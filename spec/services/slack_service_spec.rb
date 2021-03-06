require 'spec_helper'

describe SlackService do
  subject(:slack_service) { SlackService }

  let(:user) { User.new email: 'random@random.com' }

  before { Features.slack.notifications.enabled = true }

  describe '.post_hangout_notification' do
    let(:slack_client) { double(:slack_client) }
    let(:gitter_client) { double(:gitter_client) }

    let(:default_post_args) do
      {
          username: user.display_name,
          icon_url: user.gravatar_url,
          link_names: 1
      }
    end

    let(:message) { 'MockEvent: <mock_url|click to join>' }
    let(:here_message) { "@here #{message}" }
    let(:channel_message) { "@channel #{message}" }

    let(:general_channel_post_args) do
      {
          channel: 'C0TLAE1MH',
          text: here_message,
      }.merge!(default_post_args)
    end
    let(:websiteone_project_channel_post_args) do
      {
          channel: 'C29J4QQ9W',
          text: here_message,
      }.merge!(default_post_args)
    end
    let(:localsupport_project_channel_post_args) do
      {
          channel: 'C69J9GC1Y',
          text: here_message,
      }.merge!(default_post_args)
    end
    let(:cs169_project_channel_post_args) do
      {
          channel: 'C29J4CYA2',
          text: here_message,
      }.merge!(default_post_args)
    end
    let(:pairing_notifications_channel_post_args) do
      {
          channel: 'C29J3DPGW',
          text: channel_message,
      }.merge!(default_post_args)
    end
    let(:standup_notifications_channel_post_args) do
      {
          channel: 'C29JE6HGR',
          text: channel_message,
      }.merge!(default_post_args)
    end

    let(:cs169_project) { mock_model Project, slug: 'cs169' }
    let(:websiteone_project) { mock_model Project, slug: 'websiteone' }

    context('PairProgramming') do

      let(:cs169_hangout) { mock_model EventInstance, title: 'MockEvent', category: "PairProgramming", hangout_url: "mock_url", user: user, project: cs169_project }
      let(:missing_url_hangout) { mock_model EventInstance, title: 'MockEvent', category: "PairProgramming", hangout_url: "  ", user: user }
      let(:websiteone_hangout) { mock_model EventInstance, title: 'MockEvent', category: "PairProgramming", hangout_url: "mock_url", user: user, project: websiteone_project }
      let(:no_project_hangout) { mock_model EventInstance, title: 'MockEvent', category: "PairProgramming", hangout_url: "mock_url", user: user, project: nil }

      it 'sends the correct slack message to the correct channels when associated with a project' do
        expect(slack_client).to receive(:chat_postMessage).with(general_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(websiteone_project_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(pairing_notifications_channel_post_args)

        slack_service.post_hangout_notification(websiteone_hangout, slack_client, gitter_client)
      end

      it 'does not fail when event has no associated project' do
        expect(slack_client).to receive(:chat_postMessage).with(general_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(pairing_notifications_channel_post_args)

        slack_service.post_hangout_notification(no_project_hangout, slack_client, gitter_client)
      end

      it 'should ping gitter and slack (but not general) when the project is cs169' do
        expect(gitter_client).to receive(:messages).with('56b8bdffe610378809c070cc', limit: 50).and_return([])
        expect(gitter_client).to receive(:send_message).with('[MockEvent with random](mock_url) is starting NOW!', "56b8bdffe610378809c070cc")
        expect(slack_client).to receive(:chat_postMessage).with(pairing_notifications_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(cs169_project_channel_post_args)

        slack_service.post_hangout_notification(cs169_hangout, slack_client, gitter_client)
      end

      it 'does not post notification if hangout url is blank' do
        expect(slack_client).not_to receive(:chat_postMessage)

        slack_service.post_hangout_notification(missing_url_hangout, slack_client, gitter_client)
      end

      let(:multiple_channel_project) { mock_model Project, slug: 'multiple-channels' }
      let(:multiple_channel_hangout) { mock_model EventInstance, title: 'MockEvent', category: "PairProgramming", hangout_url: "mock_url", user: user, project: multiple_channel_project }

      it 'can post to multiple channels' do
        expect(slack_client).to receive(:chat_postMessage).with(general_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(websiteone_project_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(localsupport_project_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(pairing_notifications_channel_post_args)

        slack_service.post_hangout_notification(multiple_channel_hangout, slack_client, gitter_client)
      end
    end

    context('Scrums') do
      let(:cs169_hangout) { mock_model EventInstance, title: 'MockEvent', category: "Scrum", hangout_url: "mock_url", user: user, project: cs169_project }
      let(:missing_url_hangout) { mock_model EventInstance, title: 'MockEvent', category: "Scrum", hangout_url: "  ", user: user }
      let(:websiteone_hangout) { mock_model EventInstance, title: 'MockEvent', category: "Scrum", hangout_url: "mock_url", user: user, project: websiteone_project }
      let(:no_project_hangout) { mock_model EventInstance, title: 'MockEvent', category: "Scrum", hangout_url: "mock_url", user: user, project: nil }

      it 'sends the correct slack message to the correct channels' do
        expect(slack_client).to receive(:chat_postMessage).with(general_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(websiteone_project_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(standup_notifications_channel_post_args)

        slack_service.post_hangout_notification(websiteone_hangout, slack_client, gitter_client)
      end

      it 'does not fail when event has no associated project' do

        expect(slack_client).to receive(:chat_postMessage).with(general_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(standup_notifications_channel_post_args)

        slack_service.post_hangout_notification(no_project_hangout, slack_client, gitter_client)
      end

      it 'should ping slack when the project is cs169' do
        expect(slack_client).to receive(:chat_postMessage).with(general_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(cs169_project_channel_post_args)
        expect(slack_client).to receive(:chat_postMessage).with(standup_notifications_channel_post_args)

        slack_service.post_hangout_notification(cs169_hangout, slack_client, gitter_client)
      end

      it 'does not post notification if hangout url is blank for pairing' do
        expect(slack_client).not_to receive(:chat_postMessage)

        slack_service.post_hangout_notification(missing_url_hangout, slack_client, gitter_client)
      end

    end
  end

  describe '.post_yt_link' do
    let(:client) { spy(:slack_client) }
    let(:expected_post_args) do
      {
          text: 'Video/Livestream: <https://youtu.be/mock_url|click to play>',
          username: user.display_name,
          icon_url: user.gravatar_url,
          link_names: 1
      }
    end
    context('PairProgramming') do
      let(:hangout) { EventInstance.create(title: 'MockEvent', category: "PairProgramming", hangout_url: "mock_url", user: user) }

      it 'sends the correct slack message to the correct channels' do
        hangout.yt_video_id = 'mock_url'
        hangout.project = Project.create(title: 'WebSiteOne', description: 'hmmm', status: 'active')

        slack_service.post_yt_link(hangout, client)

        expect(client).to have_received(:chat_postMessage).with(expected_post_args.merge!(channel: 'C0TLAE1MH'))
        expect(client).to have_received(:chat_postMessage).with(expected_post_args.merge!(channel: 'C29J4QQ9W'))
      end

      it 'does not ping slack when the project is cs169' do
        hangout.yt_video_id = 'mock_url'
        hangout.project = Project.create(title: 'cs169', description: 'hmmm', status: 'active')

        slack_service.post_yt_link(hangout, client)

        expect(client).not_to have_received(:chat_postMessage).with(expected_post_args.merge!(channel: 'C0TLAE1MH'))
        expect(client).not_to have_received(:chat_postMessage).with(expected_post_args.merge!(channel: 'C29J4QQ9W'))
      end

      it 'does not post youtube video link if yt_video_id is blank' do
        hangout.yt_video_id = '    '
        slack_service.post_yt_link(hangout, client)

        expect(client).not_to have_received(:chat_postMessage)
      end
    end

    context('Scrums') do
      let(:hangout) { EventInstance.create(title: 'MockEvent', category: 'Scrum', hangout_url: 'mock_url', user: user) }

      it 'sends the correct slack message to the correct channels' do
        hangout.yt_video_id = 'mock_url'
        hangout.project = Project.create(slug: 'websiteone', title: 'WebSiteOne', description: 'hmmm', status: 'active')

        slack_service.post_yt_link(hangout, client)

        expect(client).to have_received(:chat_postMessage).with(expected_post_args.merge!(channel: 'C0TLAE1MH'))
        expect(client).to have_received(:chat_postMessage).with(expected_post_args.merge!(channel: 'C29J4QQ9W'))
      end

      it 'does not post youtube video link if yt_video_id is blank' do
        hangout.yt_video_id = '    '
        slack_service.post_yt_link(hangout, client)

        expect(client).not_to have_received(:chat_postMessage)
      end
    end
  end
end
