require 'test_helper'

class CtiCallerIdTest < ActiveSupport::TestCase

  setup do

    Ticket.destroy_all
    Cti::CallerId.destroy_all
    @agent1 = User.create_or_update(
      login:         'ticket-caller_id-agent1@example.com',
      firstname:     'CallerId',
      lastname:      'Agent1',
      email:         'ticket-caller_id-agent1@example.com',
      active:        true,
      phone:         '+49 1111 222222',
      fax:           '+49 1111 222223',
      mobile:        '+49 1111 222223',
      note:          'Phone at home: +49 1111 222224',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent2 = User.create_or_update(
      login:         'ticket-caller_id-agent2@example.com',
      firstname:     'CallerId',
      lastname:      'Agent2',
      email:         'ticket-caller_id-agent2@example.com',
      phone:         '+49 2222 222222',
      note:          'Phone at home: <b>+49 2222 222224</b>',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent3 = User.create_or_update(
      login:         'ticket-caller_id-agent3@example.com',
      firstname:     'CallerId',
      lastname:      'Agent3',
      email:         'ticket-caller_id-agent3@example.com',
      phone:         '+49 2222 222222',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    @customer1 = User.create_or_update(
      login:         'ticket-caller_id-customer1@example.com',
      firstname:     'CallerId',
      lastname:      'Customer1',
      email:         'ticket-caller_id-customer1@example.com',
      phone:         '+49 123 456',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    Scheduler.worker(true)
  end

  test 'not answered should be not marked as done' do

    Cti::Log.process(
      'cause'     => '',
      'event'     => 'newCall',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause'     => '',
      'event'     => 'hangup',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, false)
  end

  test 'answered should be marked as done' do

    Cti::Log.process(
      'cause'     => '',
      'event'     => 'newCall',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause'     => '',
      'event'     => 'answer',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )
    last = Cti::Log.last
    assert_equal(last.state, 'answer')
    assert_equal(last.done, true)

    travel 2.seconds
    Cti::Log.process(
      'cause'     => '',
      'event'     => 'hangup',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, true)
  end

  test 'voicemail should not be marked as done' do

    Cti::Log.process(
      'cause'     => '',
      'event'     => 'newCall',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    Cti::Log.process(
      'cause'     => '',
      'event'     => 'answer',
      'user'      => 'voicemail',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )
    last = Cti::Log.last
    assert_equal(last.state, 'answer')
    assert_equal(last.done, true)

    travel 2.seconds
    Cti::Log.process(
      'cause'     => '',
      'event'     => 'hangup',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, false)
  end

  test 'forwarded should be marked as done' do

    Cti::Log.process(
      'cause'     => '',
      'event'     => 'newCall',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause'     => 'forwarded',
      'event'     => 'hangup',
      'user'      => 'user 1',
      'from'      => '491111222222',
      'to'        => '4930600000000',
      'callId'    => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, true)
  end

end
