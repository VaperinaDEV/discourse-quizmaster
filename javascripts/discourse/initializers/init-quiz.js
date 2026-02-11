import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import discourseLater from "discourse/lib/later";
import i18n from "discourse-common/helpers/i18n";

export default apiInitializer((api) => {
  api.decorateCookedElement((element, helper) => {
    const post = helper?.getModel();
    
    // Only target the Quizmaster's posts
    if (post && post.username === settings.quizmaster_username) {
      const lists = element.querySelectorAll("ul");
      
      lists.forEach((ul) => {
        if (ul.parentElement.classList.contains("quiz-options")) return;
        
        const firstItem = ul.querySelector("li");
        if (!firstItem) return;
  
        if (firstItem.innerText.trim().startsWith("A)")) {
          const wrapper = document.createElement("div");
          wrapper.classList.add("quiz-options");
          wrapper.setAttribute("data-wrap", "quiz-options");
          
          ul.parentNode.insertBefore(wrapper, ul);
          wrapper.appendChild(ul);
          
          ul.querySelectorAll("li").forEach(li => {
            li.classList.add("quiz-option-item");
            const text = li.innerText.trim();
            const letter = text.substring(0, 1);
            
            li.setAttribute("data-wrap", "quiz-btn");
            li.setAttribute("data-id", letter);
          });
        }
      });
    }
  });

  const submitAnswerViaAjax = async (answerText, postElement) => {
    if (document.body.classList.contains("quiz-submitting")) return;
    
    document.body.classList.add("quiz-submitting");

    // Get the post model to find topic and post numbers
    const topicController = api.container.lookup("controller:topic");
    const topicModel = topicController?.get("model");
    const postNumber = postElement?.getAttribute("data-post-number");

    if (!topicModel) {
      document.body.classList.remove("quiz-submitting");
      return;
    }

    try {
      // Direct AJAX call to create a new post
      await ajax("/posts", {
        type: "POST",
        data: {
          topic_id: topicModel.id,
          raw: answerText,
          reply_to_post_number: postNumber
        }
      });
      discourseLater(() => {
        document.body.classList.remove("quiz-submitting");
      }, 500);
    } catch (error) {
      console.error("Quiz AJAX error:", error);
      
      // Basic error handling for the user
      const errorMsg = error.responseJSON?.errors?.join(", ") || "Unknown error";
      alert("Error while sending: " + errorMsg);
      
      document.body.classList.remove("quiz-submitting");
    }
  };

  document.addEventListener("click", (e) => {
    const quizBtn = e.target.closest('a[href^="#quiz-"], [data-wrap="quiz-btn"]');
    if (!quizBtn) return;

    e.preventDefault();
    if (document.body.classList.contains("quiz-submitting")) return;

    const rawAnswer = quizBtn.innerText.trim();
    const fullAnswer = `${i18n(themePrefix("my_answer"))} **${rawAnswer}**`;
    
    const postElement = quizBtn.closest('.topic-post');
    
    // Switch to the AJAX method
    submitAnswerViaAjax(fullAnswer, postElement);

  }, true);
});
