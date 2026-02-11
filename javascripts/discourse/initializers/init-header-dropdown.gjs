import { apiInitializer } from "discourse/lib/api";
import HeaderQuizButton from "../components/header-quiz-button";

export default apiInitializer("1.8.0", (api) => {
  const currentUser = api.getCurrentUser();
  const userCanSendPm = currentUser?.can_send_private_messages;
  let showUserGroup = false;

  if (currentUser && currentUser.groups) {
    const allowedGroupIds = settings.show_for_groups.split("|").map(id => parseInt(id, 10));
  
    for (var i = 0; i < currentUser.groups.length; i++) {
      if (allowedGroupIds.includes(currentUser.groups[i].id)) {
        showUserGroup = true;
        break;
      }
    }
  }

  if (!userCanSendPm || !showUserGroup) {
    return;
  }

  api.headerIcons.add("quiz", HeaderQuizButton, { before: "search" });
});
