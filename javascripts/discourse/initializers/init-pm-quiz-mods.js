import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  api.onPageChange(() => {
    const topicController = api.container.lookup("controller:topic");
    const participants = topicController?.get("model.details.allowed_users");

    if (participants && participants.some(u => u.username === settings.quizmaster_username)) {
      document.body.classList.add("is-quiz-chat");
    } else {
      document.body.classList.remove("is-quiz-chat");
    }
  });

  api.registerValueTransformer(
    "post-menu-buttons",
    ({ value: dag, context: { post } }) => {
      const user = api.getCurrentUser();
      if (!user || !post) return;
      
      const isAdmin = user && user.admin;
      const isTopicCreator = post.topic && post.topic.user_id === user.id;
      const isQuizmasterPost = post.username === settings.quizmaster_username;
      
      if (isQuizmasterPost && !isAdmin) {
        dag.delete("ai-retry");
        dag.delete("ai-share");
        if (post.topic && post.topic.archetype === "private_message") {
          dag.delete("reply");
        }
      }

      if (isTopicCreator && !isAdmin && document.body.classList.contains("is-quiz-chat")) {
        dag.delete("delete");
      }
    }
  );
});
