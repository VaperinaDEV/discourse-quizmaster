import { action } from "@ember/object";
import Service, { service } from "@ember/service";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";

export default class HiddenSubmit extends Service {
  @service composer;
  @service dialog;

  @action
  async submitToQuizmaster(messageTemplate) {
    this.composer.close();
    
    await this.composer.open({
      action: Composer.PRIVATE_MESSAGE,
      draftKey: "private_message_ai",
      recipients: settings.quizmaster_username,
      topicTitle: i18n("discourse_ai.ai_bot.default_pm_prefix"),
      topicBody: i18n(themePrefix(messageTemplate)),
      archetypeId: "private_message",
      warningsDisabled: true,
      skipDraftCheck: true,
      disableDrifts: true,
    });

    try {
      await this.composer.save();
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("Failed to submit message:", error);
    }
  }
}
