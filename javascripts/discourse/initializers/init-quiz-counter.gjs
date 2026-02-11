import Component from "@glimmer/component";
import { withPluginApi } from "discourse/lib/plugin-api";
import i18n from "discourse-common/helpers/i18n";

class QuestionCounter extends Component {
  static shouldRender(args) {
    const post = args.post;
    if (!post || !post.topic || post.topic.archetype !== "private_message") return false;

    const isQuizmasterPost = post.username === settings.quizmaster_username;

    return isQuizmasterPost;
  }

  get questionNumber() {
    return Math.floor(this.args.post.post_number / 2);
  }

  get maxQuestions() {
    return settings.quiz_max_questions || 50;
  }

  get counterText() {
    const count = `${this.questionNumber}/${this.maxQuestions}`;
    const message = i18n(themePrefix("max_questions_text")); 
    return `${count} ${message}`;
  }

  <template>
    <span class="quiz-question-counter">
      {{this.counterText}}
    </span>
  </template>
}

export default {
  name: "quiz-question-counter",
  initialize() {
    withPluginApi("1.20.0", (api) => {
      api.renderAfterWrapperOutlet("post-content-cooked-html", QuestionCounter, (args) => {
        return {
          post: args.post,
        };
      });
    });
  },
};
