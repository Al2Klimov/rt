use strict;
use warnings;

use RT::Test tests => undef;

my ( $baseurl, $m ) = RT::Test->started_ok;
ok $m->login, 'logged in as root';

my $queue = RT::Test->load_or_create_queue( Name => 'General' );
ok $queue && $queue->id, 'loaded or created queue';

my $cf = RT::Test->load_or_create_custom_field(
    Name         => 'External ID',
    Queue        => 'General',
    Type         => 'FreeformSingle',
    UniqueValues => 1,
);
my $cf_id = $cf->Id;

$m->goto_create_ticket($queue);
$m->submit_form_ok(
    {
        form_name => 'TicketCreate',
        fields    => { Subject => 'Test unique values', "Object-RT::Ticket--CustomField-$cf_id-Value" => '123' },
    },
    'Create ticket with cf value 123',
);

$m->text_like(qr/Ticket \d+ created in queue/);
my $ticket = RT::Test->last_ticket;
is( $ticket->FirstCustomFieldValue($cf), 123, 'CF value is set' );

$m->goto_create_ticket($queue);
$m->submit_form_ok(
    {
        form_name => 'TicketCreate',
        fields    => { Subject => 'Test unique values', "Object-RT::Ticket--CustomField-$cf_id-Value" => '123' },
    },
    'Create ticket with cf value 123',
);
$m->text_contains("'123' is not a unique value");
$m->text_unlike(qr/Ticket \d+ created in queue/);

$m->submit_form_ok(
    {
        form_name => 'TicketCreate',
        fields    => { Subject => 'Test unique values', "Object-RT::Ticket--CustomField-$cf_id-Value" => '456' },
    },
    'Create ticket with cf value 456'
);
$m->text_like(qr/Ticket \d+ created in queue/);
$ticket = RT::Test->last_ticket;
is( $ticket->FirstCustomFieldValue($cf), 456, 'CF value is set' );
my $ticket_id = $ticket->Id;

$m->follow_link_ok( { text => 'Basics' } );
$m->submit_form_ok(
    {
        form_name => 'TicketModify',
        fields    => { "Object-RT::Ticket-$ticket_id-CustomField-$cf_id-Value" => '123' },
    },
    'Update ticket with cf value 123'

);
$m->text_contains("'123' is not a unique value");
$m->text_lacks( 'External ID 456 changed to 123', 'Can not change to an existing value' );

$m->submit_form_ok(
    {

        form_name => 'TicketModify',
        fields    => { "Object-RT::Ticket-$ticket_id-CustomField-$cf_id-Value" => '789' },
    },
    'Update ticket with cf value 789'
);
$m->text_contains( 'External ID 456 changed to 789', 'Changed cf to a new value' );

$m->submit_form_ok(
    {

        form_name => 'TicketModify',
        fields    => { "Object-RT::Ticket-$ticket_id-CustomField-$cf_id-Value" => '456' },
    },
    'Update ticket with cf value 456'
);
$m->text_contains( 'External ID 789 changed to 456', 'Changed cf back to old value' );

done_testing;
