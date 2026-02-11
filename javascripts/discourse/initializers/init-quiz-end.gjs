import Component from "@glimmer/component";
import { withPluginApi } from "discourse/lib/plugin-api";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import discourseLater from "discourse/lib/later";
import DButton from "discourse/components/d-button";
import i18n from "discourse-common/helpers/i18n";

// Track topics that are being terminated (in-memory per session)
const terminatingTopics = new Set();

function setupQuizEndButton(api) {
  api.renderAfterWrapperOutlet(
    "post-article",
    class extends Component {
      @tracked isSubmitting = false;

      static shouldRender(args) {
        const post = args.post;
        if (!post || !post.topic || post.topic.archetype !== "private_message") return false;
        if (post.username !== settings.quizmaster_username) return false;
        if (post.post_number !== post.topic.highest_post_number) return false;

        const postsCount = post.topic.posts_count;
        const maxPosts = (settings.quiz_max_questions || 50) * 2;

        const quizmasterPostCount = Math.floor(post.post_number / 2);
        const isTenMilestone = quizmasterPostCount >= 11 && (quizmasterPostCount - 1) % 10 === 0;
        const isHardLimit = postsCount >= maxPosts && post.username === settings.quizmaster_username;

        return isTenMilestone || isHardLimit;
      }

      get isOverLimit() {
        const post = this.args.post;
        const maxPosts = (settings.quiz_max_questions || 50) * 2;
        return post && post.topic.posts_count >= maxPosts;
      }

      get hasTerminationPostAfterLimit() {
        const post = this.args.post;
        if (!post) return false;
        
        const maxPosts = (settings.quiz_max_questions || 50) * 2;
        const terminationText = i18n(themePrefix("terminate_quiz"));
        const stream = post.topic.postStream;
        
        if (stream && stream.posts && stream.posts.length > 0) {
          // Look for a post AFTER maxPosts that contains the termination text
          const terminationPost = stream.posts.find(p => {
            const isAfterLimit = p.post_number > maxPosts;
            const content = p.raw || p.cooked || "";
            const hasTerminationText = content.includes(terminationText);
            
            return isAfterLimit && hasTerminationText;
          });
          
          return !!terminationPost;
        }
        
        return false;
      }

      @action
      onInsert() {
        const post = this.args.post;
        const user = api.getCurrentUser();
        
        if (!post || !user) return;

        const isAllowed = user.id === post.topic.user_id;
        if (!isAllowed) return;

        const topicId = post.topic.id;
        
        // Check if already terminating in this session
        if (terminatingTopics.has(topicId)) {
          return;
        }

        // Check if termination post already exists
        if (this.hasTerminationPostAfterLimit) {
          return;
        }

        const maxPosts = (settings.quiz_max_questions || 50) * 2;

        const needsTermination = 
          post.topic.posts_count >= maxPosts && 
          post.topic.posts_count === post.topic.highest_post_number;

        if (needsTermination && !this.isSubmitting) {
          // Mark immediately to prevent duplicate runs
          terminatingTopics.add(topicId);
          
          discourseLater(() => {
            // Re-check before sending
            if (this.hasTerminationPostAfterLimit) {
              terminatingTopics.delete(topicId);
              return;
            }
            
            if (this.args.post.topic.posts_count === this.args.post.topic.highest_post_number) {
              this.terminateQuiz();
            } else {
              terminatingTopics.delete(topicId);
            }
          }, 1500);
        }
      }

      @action
      async terminateQuiz() {
        const post = this.args.post;
        
        if (!post || this.isSubmitting) return;

        // Final check before sending
        if (this.hasTerminationPostAfterLimit) {
          return;
        }

        this.isSubmitting = true;

        try {
          await ajax("/posts", {
            type: "POST",
            data: {
              topic_id: post.topic.id,
              raw: i18n(themePrefix("terminate_quiz")),
              reply_to_post_number: post.post_number
            }
          });
          
          discourseLater(() => {
            this.isSubmitting = false;
          }, 2000);
        } catch (error) {
          console.error("Quiz termination error:", error);
          this.isSubmitting = false;
          terminatingTopics.delete(post.topic.id);
        }
      }

      <template>
        <div 
          class="quiz-summary-trigger {{if this.isOverLimit 'hard-limit-reached'}}" 
          {{didInsert this.onInsert}}
        >
          <DButton
            @action={{this.terminateQuiz}}
            @icon="flag-checkered"
            @translatedLabel={{i18n (themePrefix "terminate_quiz")}}
            class="btn-primary btn-icon-text"
          />
        </div>
      </template>
    }
  );
}

export default {
  name: "quiz-end-button-final",
  initialize() {
    withPluginApi("0.8", (api) => {
      setupQuizEndButton(api);
    });
  }
};
