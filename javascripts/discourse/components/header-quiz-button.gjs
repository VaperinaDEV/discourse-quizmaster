import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import DMenu from "float-kit/components/d-menu";
import DropdownMenu from "discourse/components/dropdown-menu";
import DButton from "discourse/components/d-button";
import discourseLater from "discourse/lib/later";
import { i18n } from "discourse-i18n";

export default class HeaderQuizButton extends Component {
  @service site;
  @service hiddenSubmit;

  @action
  submitQuiz(messageTemplate) {
    this.hiddenSubmit.submitToQuizmaster(messageTemplate);
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  @action
  closeMenu() {
    discourseLater(() => {
      this.dMenu.close();
    }, 100);
  }

  <template>
    <DMenu
      @modalForMobile={{true}}
      @identifier="header-quiz-chooser"
      @interactive={{true}}
      @triggers="click"
      @icon={{settings.button_icon}}
      @label={{i18n (themePrefix "quiz")}}
      class="header-quiz-btn btn-small"
      @onRegisterApi={{this.onRegisterApi}}
    >
      <:content>
        <DropdownMenu as |dropdown|>
          {{#each settings.dropdown_items as |item|}}
            <dropdown.item>
              <DButton
                @translatedLabel={{i18n (themePrefix item.label_template)}}
                @icon={{item.icon}}
                class="btn-icon-text btn-transparent"
                @action={{this.submitQuiz item.message_template}}
                {{on "click" this.closeMenu}}
              >
                <div class="btn__description">
                  {{i18n (themePrefix item.description_template)}}
                </div>
              </DButton>
            </dropdown.item>
          {{/each}}
        </DropdownMenu>
      </:content>
    </DMenu>
  </template>
}
