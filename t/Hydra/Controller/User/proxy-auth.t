use strict;
use warnings;
use Setup;
use Test2::V0;
use HTTP::Request::Common;
use JSON::MaybeXS;

my $ctx = test_context(
    hydra_config => q|
using_frontend_proxy = 1
<proxy_auth>
  user_header = X-Remote-User
  auto_create_user = 1
</proxy_auth>
|
);

setup_catalyst_test($ctx);
my $db = $ctx->db();

subtest "Proxy authentication creates user with roles from header" => sub {
    my $req = request(GET '/current-user',
        Accept => 'application/json',
        'X-Remote-User' => 'proxyuser',
        'X-Remote-Roles' => 'admin,create-projects'
    );

    is($req->code, 200, "Request succeeds");

    my $data = decode_json($req->content());
    is($data->{"username"}, "proxyuser", "Username matches header");
    is([sort @{$data->{"userroles"}}], [sort qw(admin create-projects)], "Roles match header");

    my $user = $db->resultset('Users')->find({ username => 'proxyuser' });
    ok(defined $user, "User was created in database");
    is($user->type, "proxy", "User type is 'proxy'");
};

subtest "Proxy auth normalizes username to lowercase" => sub {
    my $req = request(GET '/current-user',
        Accept => 'application/json',
        'X-Remote-User' => 'MixedCaseUser',
        'X-Remote-Roles' => 'admin'
    );

    is($req->code, 200, "Request succeeds");
    my $data = decode_json($req->content());
    is($data->{"username"}, "mixedcaseuser", "Username is lowercased");
};

subtest "Request without header requires login" => sub {
    my $req = request(GET '/current-user',
        Accept => 'application/json'
    );

    is($req->code, 403, "Request without proxy header is denied");
};

done_testing;
