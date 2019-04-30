require 'spec_helper'

RSpec.describe SprinkleDNS::HostedZone do
  context "update data" do
    it 'should update changed data accordingly' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')
      hz_entry01 = sprinkle_entry('A', 'updatevalue.test.billetto.com.', '80.80.22.22', 60, hz.name)
      hz_entry02 = sprinkle_entry('A', 'updatettl.test.billetto.com.', '80.80.22.22', 60, hz.name)
      hz_entry01.persisted!
      hz_entry02.persisted!
      hz.resource_record_sets = [hz_entry01, hz_entry02]

      hz_entry03 = sprinkle_entry('A', 'updatevalue.test.billetto.com.', '90.90.22.22', 60, hz.name)
      hz_entry04 = sprinkle_entry('A', 'updatettl.test.billetto.com.', '80.80.22.22', 120, hz.name)
      [hz_entry03, hz_entry04].each do |hz_entry|
        hz.add_or_update_hosted_zone_entry(hz_entry)
      end

      updatedvalue = hz.resource_record_sets.select{|rrs| rrs.name == 'updatevalue.test.billetto.com.'}.first
      expect(updatedvalue.changed_value).to eq true
      expect(updatedvalue.changed_ttl).to eq false

      updatedttl = hz.resource_record_sets.select{|rrs| rrs.name == 'updatettl.test.billetto.com.'}.first
      expect(updatedttl.changed_value).to eq false
      expect(updatedttl.changed_ttl).to eq true
    end
  end

  context "compile_change_batch" do
    it 'should correctly calculate a compile_change_batch' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hze01 = sprinkle_entry('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      hze02 = sprinkle_entry('A', 'foo.test.billetto.com.', '80.80.23.23', 70, 'test.billetto.com.')
      hze03 = sprinkle_entry('A', 'bar.test.billetto.com.', '80.80.24.24', 80, 'test.billetto.com.')

      [hze01, hze02, hze03].each do |hze|
        hz.add_or_update_hosted_zone_entry(hze)
      end

      expect(hz.compile_change_batch).to eq([
        {:action=>"CREATE", :resource_record_set=>{:name=>"www.test.billetto.com.", :type=>"A", :ttl=>60, :resource_records=>[{:value=>"80.80.22.22"}]}},
        {:action=>"CREATE", :resource_record_set=>{:name=>"foo.test.billetto.com.", :type=>"A", :ttl=>70, :resource_records=>[{:value=>"80.80.23.23"}]}},
        {:action=>"CREATE", :resource_record_set=>{:name=>"bar.test.billetto.com.", :type=>"A", :ttl=>80, :resource_records=>[{:value=>"80.80.24.24"}]}},
      ])
    end

    context 'delete unreferenced' do
      before(:all) do
        hz = SprinkleDNS::HostedZone.new('unreferenced.com.')

        # Entries
        pe01 = sprinkle_entry('A', 'bar.unreferenced.com', '80.80.24.24', 80, 'unreferenced.com.')
        pe02 = sprinkle_entry('A', 'noref.unreferenced.com', '127.0.0.1', 80, 'unreferenced.com.')

        # We are emulating that these records are already live, mark them as persisted
        [pe01, pe02].each do |persisted|
          persisted.persisted!
          hz.resource_record_sets << persisted
        end

        client = SprinkleDNS::MockClient.new([hz])
        sdns   = SprinkleDNS::Client.new(client, delete: true)

        sdns.entry('A', 'bar.unreferenced.com', '80.80.24.24', 80)

        _, existing_hzs = sdns.compare
        @existing_hz = existing_hzs.first
      end

      it 'lol' do
        expect(@existing_hz.entries_to_delete.size).to eq 1
        delete_entry = @existing_hz.entries_to_delete.first
        expect(delete_entry.type).to eq 'A'
        expect(delete_entry.name).to eq 'noref.unreferenced.com.'

        expect(@existing_hz.compile_change_batch).to eq []
        expect(@existing_hz.compile_change_batch(delete: true)).to eq [
          {:action=>"DELETE", :resource_record_set=>{:name=>"noref.unreferenced.com.", :type=>"A", :ttl=>80, :resource_records=>[{:value=>"127.0.0.1"}]}}
        ]
      end
    end

    context 'advanced compile_change_batch' do
      before(:all) do
        hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

        # Static
        ps01 = sprinkle_entry('A', 'staticentry.test.billetto.com.', '80.80.24.24', 80, 'test.billetto.com.')
        ps02 = sprinkle_alias('A', 'staticalias.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

        # Entries
        pe01 = sprinkle_entry('A', 'bar.test.billetto.com.', '80.80.24.24', 80, 'test.billetto.com.')
        pe02 = sprinkle_entry('A', 'noref.test.billetto.com.', '127.0.0.1', 80, 'test.billetto.com.')

        # Aliases
        pa01 = sprinkle_alias('A', 'war.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')
        pa02 = sprinkle_alias('A', 'noraf.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

        # Mixed to overwrite
        pi01 = sprinkle_entry('A', 'entry-to-alias.test.billetto.com.', '80.80.24.24', 80, 'test.billetto.com.')
        pi02 = sprinkle_alias('A', 'alias-to-entry.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

        # We are emulating that these records are already live, mark them as persisted
        [ps01, ps02, pe01, pe02, pa01, pa02, pi01, pi02].each do |persisted|
          persisted.persisted!
          hz.resource_record_sets << persisted
        end

        client = SprinkleDNS::MockClient.new([hz])
        sdns   = SprinkleDNS::Client.new(client)

        # Static entries
        sdns.entry('A', 'staticentry.test.billetto.com.', '80.80.24.24', 80, 'test.billetto.com.')
        sdns.alias('A', 'staticalias.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

        # PURE ENTRIES
        # Adds new
        sdns.entry('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')

        # Adds new and overwrites
        sdns.entry('A', 'foo.test.billetto.com.', '80.80.23.23', 70, 'test.billetto.com.')
        sdns.entry('A', 'foo.test.billetto.com.', '81.81.24.24', 80, 'test.billetto.com.')

        # Modifies existing
        sdns.entry('A', 'bar.test.billetto.com.', '82.82.26.26', 90, 'test.billetto.com.')

        # PURE ALIASES
        # Adds new
        sdns.alias('A', 'wap.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

        # Adds new and overwrites
        sdns.alias('A', 'woo.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')
        sdns.alias('A', 'woo.test.billetto.com.', 'Z215JYRZR1TBD6', 'dualstack.mothership-test-elb-444444444.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

        # Modifies existing
        sdns.alias('A', 'war.test.billetto.com.', 'Z215JYRZR1TBD6', 'dualstack.mothership-test-elb-444444444.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

        # MIXED ENTRIES/ALIASES OVERWRITE
        sdns.alias('A', 'entry-to-alias.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')
        sdns.entry('A', 'alias-to-entry.test.billetto.com.', '80.80.24.24', 80, 'test.billetto.com.')

        _, existing_hzs = sdns.compare
        @existing_hz = existing_hzs.first
      end

      it "should have a correct number of changes" do
        expect(@existing_hz.entries_to_create.size).to eq 4
        expect(@existing_hz.entries_to_update.size).to eq 4
        expect(@existing_hz.entries_to_delete.size).to eq 2
        expect(@existing_hz.entries_not_touched.size).to eq 2
      end

      context "references should be correct for" do
        it "entries" do
          ['www.test.billetto.com.', 'foo.test.billetto.com.', 'bar.test.billetto.com.'].each do |referenced|
            expect(@existing_hz.resource_record_sets
              .select{|r| r.name == referenced}
              .select{|r| r.class == SprinkleDNS::HostedZoneEntry}
              .first.referenced?).to eq true
          end
          ['noref.test.billetto.com.'].each do |unreferenced|
            expect(@existing_hz.resource_record_sets
              .select{|r| r.name == unreferenced}
              .select{|r| r.class == SprinkleDNS::HostedZoneEntry}
              .first.referenced?).to eq false
          end
        end

        it "aliases" do
          ['wap.test.billetto.com.', 'woo.test.billetto.com.', 'war.test.billetto.com.'].each do |referenced|
            expect(@existing_hz.resource_record_sets
              .select{|r| r.name == referenced}
              .select{|r| r.class == SprinkleDNS::HostedZoneAlias}
              .first.referenced?).to eq true
          end
          ['noraf.test.billetto.com.'].each do |unreferenced|
            expect(@existing_hz.resource_record_sets
              .select{|r| r.name == unreferenced}
              .select{|r| r.class == SprinkleDNS::HostedZoneAlias}
              .first.referenced?).to eq false
          end
        end

        it "mixed" do
          entry_to_alias = @existing_hz.resource_record_sets.select{|r| r.name == 'entry-to-alias.test.billetto.com.'}.first
          expect(entry_to_alias.referenced?).to eq true
          expect(entry_to_alias.class).to eq SprinkleDNS::HostedZoneEntry
          expect(entry_to_alias.new_entry.class).to eq SprinkleDNS::HostedZoneAlias

          alias_to_entry = @existing_hz.resource_record_sets.select{|r| r.name == 'alias-to-entry.test.billetto.com.'}.first
          expect(alias_to_entry.referenced?).to eq true
          expect(alias_to_entry.class).to eq SprinkleDNS::HostedZoneAlias
          expect(alias_to_entry.new_entry.class).to eq SprinkleDNS::HostedZoneEntry
        end
      end

      context "entries should be correctly set for" do
        it 'entries' do
          expect(@existing_hz.entries_to_create.map(&:name)).to include('www.test.billetto.com.', 'foo.test.billetto.com.')
          expect(@existing_hz.entries_to_update.map(&:name)).to include('bar.test.billetto.com.')
          expect(@existing_hz.entries_to_delete.map(&:name)).to include('noref.test.billetto.com.')
        end

        it 'aliases' do
          expect(@existing_hz.entries_to_create.map(&:name)).to include('wap.test.billetto.com.', 'woo.test.billetto.com.')
          expect(@existing_hz.entries_to_update.map(&:name)).to include('war.test.billetto.com.')
          expect(@existing_hz.entries_to_delete.map(&:name)).to include('noraf.test.billetto.com.')
        end

        it "mixed" do
          expect(@existing_hz.entries_to_update.map(&:name)).to include('entry-to-alias.test.billetto.com.', 'alias-to-entry.test.billetto.com.')
        end
      end

      it "should calculate complicated compile_change_batch" do
        expect(@existing_hz.compile_change_batch).to eq [
          {:action=>"UPSERT", :resource_record_set=>{:name=>"bar.test.billetto.com.", :type=>"A", :ttl=>90, :resource_records=>[{:value=>"82.82.26.26"}]}},
          {:action=>"UPSERT", :resource_record_set=>{:name=>"war.test.billetto.com.", :type=>"A", :alias_target=>{:hosted_zone_id=>"Z215JYRZR1TBD6", :dns_name=>"dualstack.mothership-test-elb-444444444.eu-central-1.elb.amazonaws.com", :evaluate_target_health=>false}}},
          {:action=>"UPSERT", :resource_record_set=>{:name=>"entry-to-alias.test.billetto.com.", :type=>"A", :alias_target=>{:hosted_zone_id=>"Z215JYRZR1TBD5", :dns_name=> "dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com", :evaluate_target_health=>false}}},
          {:action=>"UPSERT", :resource_record_set=>{:name=>"alias-to-entry.test.billetto.com.", :type=>"A", :ttl=>80, :resource_records=>[{:value=>"80.80.24.24"}]}},
          {:action=>"CREATE", :resource_record_set=>{:name=>"www.test.billetto.com.", :type=>"A", :ttl=>60, :resource_records=>[{:value=>"80.80.22.22"}]}},
          {:action=>"CREATE", :resource_record_set=>{:name=>"foo.test.billetto.com.", :type=>"A", :ttl=>80, :resource_records=>[{:value=>"81.81.24.24"}]}},
          {:action=>"CREATE", :resource_record_set=>{:name=>"wap.test.billetto.com.", :type=>"A", :alias_target=>{:hosted_zone_id=>"Z215JYRZR1TBD5", :dns_name=>"dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com", :evaluate_target_health=>false}}},
          {:action=>"CREATE", :resource_record_set=>{:name=>"woo.test.billetto.com.", :type=>"A", :alias_target=>{:hosted_zone_id=>"Z215JYRZR1TBD6", :dns_name=>"dualstack.mothership-test-elb-444444444.eu-central-1.elb.amazonaws.com", :evaluate_target_health=>false}}},
        ]
      end
    end
  end

  context "overwrite an entry" do
    it 'should correctly replace an entry if not persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_entry = sprinkle_entry('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      expect(hz_entry.persisted?).to eq false
      hz_alias = sprinkle_alias('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')
      expect(hz_alias.persisted?).to eq false

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).to include(hz_alias)
      expect(hz.resource_record_sets).not_to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1
    end

    it 'should use #new_value if persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_entry = sprinkle_entry('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      hz_alias = sprinkle_alias('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

      hz_entry.persisted!

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).not_to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1
      expect(hz.resource_record_sets.first.new_entry).to eq hz_alias
    end
  end

  context "overwrite an alias" do
    it 'should correctly replace an alias if not persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_alias = sprinkle_alias('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')
      expect(hz_alias.persisted?).to eq false
      hz_entry = sprinkle_entry('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      expect(hz_entry.persisted?).to eq false

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets).not_to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1
    end

    it 'should use #new_value if persisted' do
      hz = SprinkleDNS::HostedZone.new('test.billetto.com.')

      hz_entry = sprinkle_entry('A', 'www.test.billetto.com.', '80.80.22.22', 60, 'test.billetto.com.')
      hz_alias = sprinkle_alias('A', 'www.test.billetto.com.', 'Z215JYRZR1TBD5', 'dualstack.mothership-test-elb-546580691.eu-central-1.elb.amazonaws.com', 'test.billetto.com.')

      hz_entry.persisted!

      hz.add_or_update_hosted_zone_entry(hz_entry)
      expect(hz.resource_record_sets).to include(hz_entry)
      expect(hz.resource_record_sets.size).to eq 1

      hz.add_or_update_hosted_zone_entry(hz_alias)
      expect(hz.resource_record_sets).not_to include(hz_alias)
      expect(hz.resource_record_sets.size).to eq 1
      expect(hz.resource_record_sets.first.new_entry).to eq hz_alias
    end
  end
end
