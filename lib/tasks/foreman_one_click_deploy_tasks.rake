# Tasks
namespace :foreman_one_click_deploy do
  namespace :golden_image do
    desc 'create golden image'
    task create: :environment do
      golden_host = Setting[:one_click_deploy_golden_server]
      save_back = (Setting[:one_click_deploy_golden_image_min_backups] - 1).to_i
      shutdown_state_string = Setting[:one_click_deploy_computeresource_shutdown_string] || 'SHUTOFF'
      metadata_tag = Setting[:one_click_deploy_golden_image_metadata_tag] || 'one_click'
      golden_image_name_prefix = Setting[:one_click_deploy_golden_image_metadata_tag] || "Golden_Image_"
      begin
        gold_inst = Host.find_by_name(golden_host)
        gold_image_id = gold_inst.image_id
        puts "Working on #{golden_host}"
      rescue => e
        Rails.logger.error "#{Time.now} Cannot find golden VM" + e.message
        puts "#{Time.now} Cannot find golden VM" + e.message
        abort 'Cannot find golden VM'
      end
      begin
        compute_resource = ComputeResource.find_by_id gold_inst.compute_resource_id
        source_host = compute_resource.find_vm_by_uuid gold_inst.uuid
        Rails.logger.info "#{Time.now} Working on VM - #{gold_inst}, UUID - #{gold_inst.uuid}"
        puts "#{Time.now} Working on VM - #{gold_inst}, UUID - #{gold_inst.uuid}"
      rescue => e
        Rails.logger.error "#{Time.now} Cannot locate golden image UUID" + e.message
        puts "#{Time.now} Cannot locate golden image UUID" + e.message
        abort 'Cannot locate golden image UUID'
      end

      # Shutoff vm before creating snap
      if source_host.nil?
        abort 'No source host UUID found'
      end


      shutdown_count_limit = Setting[:one_click_deploy_golden_image_shutdown_ticks] || 24
      shutdown_sleep_interval = Setting[:one_click_deploy_golden_image_shutdown_sleep_interval] || 5
      shutoff_count = 1
      begin
        if compute_resource.find_vm_by_uuid(gold_inst.uuid).state == shutdown_state_string
          break 'VM is SHUTOFF, will create image now'
        else
          compute_resource.stop_vm gold_inst.uuid
          until shutoff_count == shutdown_count_limit + 1
            break if compute_resource.find_vm_by_uuid(gold_inst.uuid).state == shutdown_state_string
            Rails.logger.info "#{Time.now} Stopping source VM. retry number #{shutoff_count}"
            puts "#{Time.now} Stopping source VM. retry number #{shutoff_count}"
            shutoff_count += 1
            sleep shutdown_sleep_interval
          end
        end
        if (shutoff_count == shutdown_count_limit + 1) && compute_resource.find_vm_by_uuid(gold_inst.uuid).state != shutdown_state_string
          Rails.logger.info "#{Time.now} Failed to shutdown machine after #{shutdown_count_limit} tries"
          puts "#{Time.now} Failed to shutdown machine after #{shutdown_count_limit} tries"
          abort "Failed to shutdown machine after #{shutdown_count_limit} tries"
        end
      rescue => e
        Rails.logger.info "#{Time.now} Caught exception while trying to stop machine. " + e.message
        puts "#{Time.now} Caught exception while trying to stop machine. " + e.message
      end

      # Create image from volume
      image_from_volume_count_limit = Setting[:one_click_deploy_golden_image_image_from_volume_ticks] || 24
      image_from_volume_sleep_interval = Setting[:one_click_deploy_golden_image_image_from_volume_sleep_interval] || 5
      image_from_volume_count = 1
      t = Time.now
      begin
        snapshot = source_host.create_image("#{golden_image_name_prefix}{#{t.strftime('%Y-%m-%d_%H:%M')}", metadata = { metadata_tag => 'true' })
        img_id = snapshot[:body]['image']['id']
        until image_from_volume_count == image_from_volume_count_limit
          break if compute_resource.snapshot_status(img_id) == 'ACTIVE'
          image_from_volume_count += 1
          sleep image_from_volume_sleep_interval
        end
        if image_from_volume_count == image_from_volume_count_limit && compute_resource.snapshot_status(img_id) != 'ACTIVE'
          Rails.logger.info "#{Time.now} Image is not ACTIVE after #{image_from_volume_count_limit * image_from_volume_sleep_interval} seconds"
          puts "#{Time.now} Image is not ACTIVE after #{image_from_volume_count_limit * image_from_volume_sleep_interval} seconds"
          abort "Image is not ACTIVE after #{image_from_volume_count_limit * image_from_volume_sleep_interval} seconds"
        end
      rescue => e
        Rails.logger.info "#{Time.now} Caught exception while trying to stop machine. " + e.message
        puts "#{Time.now} Caught exception while trying to stop machine. " + e.message
      end

      #TODO: Continue from here
      # Start gold_inst vm
      count_limit = 24
      sleep_interval = 5
      shutoff_count = 0
      begin
        if compute_resource.find_vm_by_uuid(gold_inst.uuid).state == 'ACTIVE'
          break 'VM is ACTIVE, check that image was created' # TODO: should this return error?
        else
          compute_resource.start_vm gold_inst.uuid
          until shutoff_count == count_limit
            break if compute_resource.find_vm_by_uuid(gold_inst.uuid).state == 'ACTIVE'
            Rails.logger.info "#{Time.now} Starting source VM. retry number #{shutoff_count}"
            puts "#{Time.now} Starting source VM. retry number #{shutoff_count}"
            shutoff_count += 1
            sleep sleep_interval
          end
        end
        if shutoff_count == count_limit && compute_resource.find_vm_by_uuid(gold_inst.uuid).state != 'ACTIVE'
          Rails.logger.info "Failed to start machine after #{count_limit} tries"
          puts "Failed to start machine after #{count_limit} tries"
          abort "Failed to start machine after #{count_limit} tries"
        end
      rescue => e
        Rails.logger.info "#{Time.now} Caught exception while trying to stop machine. " + e.message
        puts "#{Time.now} Caught exception while trying to stop machine. " + e.message
      end

      # Update UUID of golden image on Foreman
      begin
        gold_image = Image.find_by_id(gold_image_id)
        gold_image.uuid = img_id
        gold_image.save!
        Rails.logger.info "#{Time.now} Updated Golden Imgae on forman with new UUID"
        puts "#{Time.now} Updated Golden Imgae on forman with new UUID"
      rescue => e
        Rails.logger.info "#{Time.now} Could not update new UUID on Foreman" + e.message
        puts "#{Time.now} Could not update new UUID on Foreman" + e.message
        abort 'Could not update new UUID on Foreman'
      end

      # Search for all images with stgil meta tag
      begin
        stg_il_images = compute_resource.available_images.select { |x| x.metadata.to_hash[metadata_tag] == 'true' }
      rescue => e
        Rails.logger.info "#{Time.now} Could not find old images" + e.message
        puts "#{Time.now} Could not find old images" + e.message
        abort 'Could notfind old images'
      end

      # Create array of images older than X days
      begin
        stg_il_images.sort! { |a, b| b.attributes[:created_at].to_date <=> a.attributes[:created_at].to_date }
        stg_il_images.slice!(0..save_back)
      rescue => e
        Rails.logger.info "#{Time.now} Caught an exaption during image filtration." + e.message
        puts "#{Time.now} Caught an exaption during image filtration." + e.message
      end
      begin
        if stg_il_images.empty?
          Rails.logger.info "#{Time.now} There are no images to delete, exiting"
          puts "#{Time.now} There are no images to delete, exiting"
          abort 'There are no images to delete, exiting'
        end
        stg_il_images.each do |image|
          if image.attributes[:created_at].to_date < Date.today-7.days
            image_to_delete = image.attributes[:id]
            snapshot_id_to_delete = image.metadata.to_hash['block_device_mapping'][0]['snapshot_id']
            compute_resource.volume_snapshot_delete(snapshot_id_to_delete)
            Rails.logger.info "#{Time.now} Deleting the volume snapshot: - #{snapshot_id_to_delete}"
            puts "#{Time.now} Deleting the volume snapshot: - #{snapshot_id_to_delete}"
            compute_resource.image_delete(image_to_delete)
            Rails.logger.info "#{Time.now} Deleting old image: #{image.attributes[:name]} "
            puts "#{Time.now} Deleting old image: #{image.attributes[:name]} "
          else
            Rails.logger.info "#{Time.now} The image: #{image.attributes[:name]} is less than 7 days old. Will not delete"
            puts "#{Time.now} The image: #{image.attributes[:name]} is less than 7 days old. Will not delete"
          end
        end
      rescue => e
        Rails.logger.info "#{Time.now} Caught an exaption during image deletion" + e.message
        puts "#{Time.now} Caught an exaption during image deletion" + e.message
      end
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanOneClickDeploy'
  Rake::TestTask.new(:foreman_one_click_deploy) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
  end
end

namespace :foreman_one_click_deploy do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_one_click_deploy) do |task|
        task.patterns = ["#{ForemanOneClickDeploy::Engine.root}/app/**/*.rb",
                         "#{ForemanOneClickDeploy::Engine.root}/lib/**/*.rb",
                         "#{ForemanOneClickDeploy::Engine.root}/test/**/*.rb"]
      end
    rescue
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_one_click_deploy'].invoke
  end
end

Rake::Task[:test].enhance do
  Rake::Task['test:foreman_one_click_deploy'].invoke
end

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance do
    Rake::Task['test:foreman_one_click_deploy'].invoke
    Rake::Task['foreman_one_click_deploy:rubocop'].invoke
  end
end
