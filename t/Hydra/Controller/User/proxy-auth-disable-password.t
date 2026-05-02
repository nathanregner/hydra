use strict;
use warnings;
use Setup;
use Test2::V0;
use HTTP::Request::Common;

my $ctx = test_context(
    hydra_config => q|
using_frontend_proxy = 1
<proxy_auth>
  user_header = X-Remote-User
  disable_password_login = 1
</proxy_auth>
|
);

setup_catalyst_test($ctx);
my $db = $ctx->db();

my $user = $db->resultset('Users')->create({
    username => 'localuser',
    emailaddress => 'local@test.org',
    password => '!',
    type => 'hydra'
});
$user->setPassword('testpass');

subtest "Password login is blocked when disabled" => sub {
    my $req = request(POST '/login',
        Referer => 'http://localhost/',
        Content => {
            username => 'localuser',
            password => 'testpass'
        }
    );

    is($req->code, 403, "Password login returns 403");
};

subtest "Proxy auth still works" => sub {
    my $req = request(GET '/current-user',
        Accept => 'application/json',
        'X-Remote-User' => 'proxyadmin',
        'X-Remote-Roles' => 'admin'
    );

    is($req->code, 200, "Proxy auth succeeds");
};

done_testing;
