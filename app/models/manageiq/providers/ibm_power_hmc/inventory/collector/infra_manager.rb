class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector
  def initialize(manager, target)
    super
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @cecs = connection.managed_systems
      @netadapters = {}
      @sriov_elps = {}
      @vnics = {}
      do_lpars(connection)
      do_vioses(connection)
      $ibm_power_hmc_log.info("end collection")
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("managed systems query failed: #{e}")
    end
  end

  def cecs
    @cecs || []
  end

  def lpars
    @lpars || []
  end

  def vioses
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

  def do_lpars(connection)
    @lpars = @cecs.map do |sys|
      connection.lpars(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("lpars query failed for #{sys.uuid}: #{e}")
      nil
    end.flatten.compact

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

  def do_vioses(connection)
    @vioses = @cecs.map do |sys|
      connection.vioses(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("vioses query failed for #{sys.uuid} #{e}")
      nil
    end.flatten.compact

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
end
