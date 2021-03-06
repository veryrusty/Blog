=head

Author: Andrei Cacio
Email: andrei.cacio@evozon.com

=cut

package perlblog::Admin::User;

use Dancer2;
use Dancer2::Plugin::DBIC;

use Digest::SHA1 qw(sha1_hex);
use Crypt::RandPasswd qw(chars);
use Email::MIME;
use Email::Sender::Simple qw(sendmail);

=head

List all users

=cut

get '/admin/users' => sub {

	my @users = resultset('User')->search({}, { order_by => "register_date DESC" });
	
	my $all 		= scalar ( @users );
	my $activated 	= resultset('User')->search({ status => 'activated'})->count;
	my $deactivated = resultset('User')->search({ status => 'deactivated'})->count;
	my $suspended 	= resultset('User')->search({ status => 'suspended'})->count;

	template '/admin/users/list',
		{
			users 		=> \@users,
			all   		=> $all, 
			activated 	=> $activated,
			deactivated => $deactivated,
			suspended 	=> $suspended
		},
		{ layout => 'admin' };

};

=head

List all deactivated users

=cut

get '/admin/users/deactivated' => sub {

	my @users = resultset('User')->search({ status => 'deactivated' }, { order_by => "register_date DESC" });
	
	my $all 		= resultset('User')->search({})->count;
	my $activated 	= resultset('User')->search({ status => 'activated'})->count;
	my $deactivated = scalar ( @users );
	my $suspended 	= resultset('User')->search({ status => 'suspended'})->count;

	template '/admin/users/list',
		{
			users 		=> \@users,
			all   		=> $all, 
			activated 	=> $activated,
			deactivated => $deactivated,
			suspended 	=> $suspended
		},
		{ layout => 'admin' };

};

=head

List all activated users

=cut

get '/admin/users/activated' => sub {

	my @users = resultset('User')->search({ status => 'activated' }, { order_by => "register_date DESC" });
	
	my $all 		= resultset('User')->search({})->count;
	my $activated 	= scalar ( @users );
	my $deactivated = resultset('User')->search({ status => 'deactivated'});
	my $suspended 	= resultset('User')->search({ status => 'suspended'});

	template '/admin/users/list',
		{
			users 		=> \@users,
			all   		=> $all, 
			activated 	=> $activated,
			deactivated => $deactivated,
			suspended 	=> $suspended
		},
		{ layout => 'admin' };

};

=head

List all suspended users

=cut

get '/admin/users/suspended' => sub {

	my @users = resultset('User')->search({ status => 'suspended' }, { order_by => "register_date DESC" });
	
	my $all 		= resultset('User')->search({})->count;
	my $activated 	= resultset('User')->search({ status => 'activated'});
	my $deactivated = resultset('User')->search({ status => 'deactivated'});
	my $suspended 	= scalar ( @users );

	template '/admin/users/list',
		{
			users 		=> \@users,
			all   		=> $all, 
			activated 	=> $activated,
			deactivated => $deactivated,
			suspended 	=> $suspended
		},
		{ layout => 'admin' };

};

=head

Activate user

=cut

any '/admin/users/activate/:id' => sub {

	my $user_id = params->{id};
	my $user 	= resultset('User')->find( $user_id );

	eval {
		$user->update({
				status => 'activated'
			});
	};

	redirect '/admin/users';
};

=head

Deactivate user

=cut

any '/admin/users/deactivate/:id' => sub {

	my $user_id = params->{id};
	my $user 	= resultset('User')->find( $user_id );

	eval {
		$user->update({
				status => 'deactivated'
			});
	};

	redirect '/admin/users';
};

=head

Suspend user

=cut

any '/admin/users/suspend/:id' => sub {

	my $user_id = params->{id};
	my $user 	= resultset('User')->find( $user_id );

	eval {
		$user->update({
				status => 'suspended'
			});
	};

	redirect '/admin/users';
};

=head

Add a new user

=cut

any '/admin/users/add' => sub {

	if ( params->{username} ) {
		eval {
			my $username 	= params->{username};
			my $password 	= Crypt::RandPasswd::chars(10, 15);
			my $email 	 	= params->{email};
			my $first_name 	= params->{first_name};
			my $last_name 	= params->{last_name};
			my $role 	 	= params->{role};

			resultset('User')->create({
				username 	=> $username,
				password 	=> sha1_hex( $password ),
				email 	 	=> $email,
				first_name 	=> $first_name,
				last_name 	=> $last_name,
				role 		=> $role
			});

			my $body = '	
						The admin of <path> blog added you as an ' . $role . ' to this blog.
						
		 				
		 				
						Here is you login information:
						
		 				
		 				
						Username: ' . $username . '
						
						Password: ' . $password . '
						
						
						
						Sincerely,
						
						The PearlBee team
						
						http://www.PearlBee.org ';

			my $message = Email::MIME->create(
		    	header_str => [
				    From    => 'no-reply@perlblog.com',
				    To      => $email,
				    Subject => 'Welcome to PerlBlog!',
			  	],

			  	attributes => {
				    encoding => 'quoted-printable',
				    charset  => 'ISO-8859-1',
			 	},

				body_str => $body,
			);

			sendmail($message);
		};

		error $@ if ( $@ );

		if ( $@ ) {
			template 'admin/users/add', 
				{
					warning => 'Something went wrong. Please contact the administrator.'
				}, 
				{ layout => 'admin' };
		}
		else {
			template 'admin/users/add', 
				{
					success => 'The user was added succesfully and will be activated after he logs in'
				}, 
				{ layout => 'admin' };
		}
	}
	else {
		template 'admin/users/add', {},	{ layout => 'admin' };
	}	
};

1;