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
  roles_header = X-Custom-Roles
  auto_create_user = 1
</proxy_auth>
|
);

setup_catalyst_test($ctx);

subtest "Roles from custom header" => sub {
    my $req = request(GET '/current-user',
        Accept => 'application/json',
        'X-Remote-User' => 'customroles',
        'X-Custom-Roles' => 'eval-jobset,restart-jobs'
    );

    is($req->code, 200, "Request succeeds");
    my $data = decode_json($req->content());
    is([sort @{$data->{"userroles"}}], [sort qw(eval-jobset restart-jobs)], "Roles from custom header");
};

subtest "No roles when header absent" => sub {
    my $req = request(GET '/current-user',
        Accept => 'application/json',
        'X-Remote-User' => 'noroles'
    );

    is($req->code, 200, "Request succeeds");
    my $data = decode_json($req->content());
    is($data->{"userroles"}, [], "No roles assigned");
};

done_testing;
