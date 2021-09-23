class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::TargetCollection < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
  end

  def hosts
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")

    @hosts ||= begin
      references(:hosts).map do |ems_ref|
        $ibm_power_hmc_log.info("#{self.class}##{__method__} #{ems_ref}")
        connection.managed_system(ems_ref)
      end
    end
  end

  def vms
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")

    @vms ||= begin
      references(:vms).map do |ems_ref|
        $ibm_power_hmc_log.info("#{self.class}##{__method__} #{ems_ref}")
        connection.lpar(ems_ref)
      end
    end
  end

  private

  def parse_targets!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")

    target.targets.each do |target|
      case target
      when Host
        add_target(:hosts, target.ems_ref)
      when Vm
        add_target(:vms, target.ems_ref)
      end
    end
  end

  def add_target(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end

  def references(collection)
    target.manager_refs_by_association&.dig(collection, :ems_ref)&.to_a&.compact || []
  end
end