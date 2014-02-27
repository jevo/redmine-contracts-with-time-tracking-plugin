module Contracts
  class ContractsHookListener < Redmine::Hook::ViewListener

    def view_timelog_edit_form_bottom(context={})
      @current_project = Project.find(context[:time_entry].project_id)
      @contracts = @current_project.contracts_for_all_ancestor_projects
      return "" if @contracts.empty?
      if context[:time_entry].contract_id != nil
        selected_contract = context[:time_entry].contract_id
      elsif !(@contracts.select { |contract| (contract.start_date <= DateTime.now) && (DateTime.now <= contract.end_date) }.empty?)
        selected_contract = @contracts.select { |contract| (contract.start_date <= DateTime.now) && (DateTime.now <= contract.end_date) }.first.id
      else
        selected_contract = ''
      end
      db_options = options_from_collection_for_select(@contracts, :id, :title, selected_contract)
      #select contracts for user( contractor_id) or whole project
      db_user_contract = @contracts.select {|contract| contract.contractor_id == (User.current.id) || (contract.contractor_id.nil?)}
      db_options_user = options_from_collection_for_select(db_user_contract,:id, :title)
      no_contract_option = "<option value=''>-- #{l(:label_contract_empty)} -- </option>\n".html_safe
      #all_options = no_contract_option << db_options
      all_options = no_contract_option << db_options_user
      select = context[:form].select :contract_id, all_options
      return "<p>#{select}</p>"
    end

    def controller_timelog_edit_before_save(context={})
      if context[:time_entry].contract_id != nil
        contract = Contract.find(context[:time_entry].contract_id)
        unless contract.hours_remaining < 0
          hours_over = contract.exceeds_remaining_hours_by?(context[:time_entry].hours)
          msg = l(:text_time_exceeded_time_remaining, :hours_over => l_hours(hours_over), :hours_remaining => l_hours(contract.hours_remaining))
          context[:controller].flash[:error] = msg unless hours_over == 0
        end
      end
    end
  end
end
