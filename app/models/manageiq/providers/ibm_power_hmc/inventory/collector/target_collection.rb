class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::TargetCollection < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
  end

  def cecs
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    @cecs ||= manager.with_provider_connection do |connection|
      references(:hosts).map do |ems_ref|
        connection.managed_system(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying managed system #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact
    end
  end

  def lpars
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @lpars ||= references(:vms).map do |ems_ref|
        connection.lpar(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying lpar #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact

      @netadapters ||= {}
      @sriov_elps ||= {}
      @vnics ||= {}
      @lpars.each do |lpar|
        lpar.net_adap_uuids.each do |net_adap_uuid|
          @netadapters[net_adap_uuid] = connection.network_adapter_lpar(lpar.uuid, net_adap_uuid)
        rescue IbmPowerHmc::Connection::HttpError => e
          $ibm_power_hmc_log.error("network adapter query failed for #{lpar.uuid}/#{net_adap_uuid}: #{e}")
        end
        lpar.sriov_elp_uuids.each do |sriov_elp_uuid|
          @sriov_elps[sriov_elp_uuid] = connection.sriov_elp_lpar(lpar.uuid, sriov_elp_uuid)
        rescue IbmPowerHmc::Connection::HttpError => e
          $ibm_power_hmc_log.error("sriov ethernet logical port query failed for #{lpar.uuid}/#{sriov_elp_uuid}: #{e}")
        end
        lpar.vnic_dedicated_uuids.each do |vnic_dedicated_uuid|
          @vnics[vnic_dedicated_uuid] = connection.vnic_dedicated(lpar.uuid, vnic_dedicated_uuid)
        rescue IbmPowerHmc::Connection::HttpError => e
          $ibm_power_hmc_log.error("vnic query failed for #{lpar.uuid}/#{vnic_dedicated_uuid}: #{e}")
        end
      end
    end
    @lpars || []
  end

  def vioses
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @vioses ||= references(:vms).map do |ems_ref|
        connection.vios(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying vios #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact

      @netadapters ||= {}
      @sriov_elps ||= {}
      @vioses.each do |vios|
        vios.net_adap_uuids.each do |net_adap_uuid|
          @netadapters[net_adap_uuid] = connection.network_adapter_vios(vios.uuid, net_adap_uuid)
        rescue IbmPowerHmc::Connection::HttpError => e
          $ibm_power_hmc_log.error("network adapter query failed for #{vios.uuid}/#{net_adap_uuid}: #{e}")
        end
        vios.sriov_elp_uuids.each do |sriov_elp_uuid|
          @sriov_elps[sriov_elp_uuid] = connection.sriov_elp_vios(vios.uuid, sriov_elp_uuid)
        rescue IbmPowerHmc::Connection::HttpError => e
          $ibm_power_hmc_log.error("sriov ethernet logical port query failed for #{vios.uuid}/#{sriov_elp_uuid}: #{e}")
        end
      end
    end
    @vioses || []
  end

  def netadapters
    @netadapters || {}
  end

  def sriov_elps
    @sriov_elps || {}
  end

  def vnics
    @vnics || {}
  end

  private

  def parse_targets!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")

    target.targets.each do |target|
      case target
      when Host
        add_target(:hosts, target.ems_ref)
      when ManageIQ::Providers::IbmPowerHmc::InfraManager::Lpar, ManageIQ::Providers::IbmPowerHmc::InfraManager::Vios
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
