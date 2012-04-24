%%%----------------------------------------------------------------------
%%% Copyright (c) 2008-2012 Peter Lemenkov <lemenkov@gmail.com>
%%%
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without modification,
%%% are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice, this
%%% list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%% * Neither the name of the authors nor the names of its contributors
%%% may be used to endorse or promote products derived from this software
%%% without specific prior written permission.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ''AS IS'' AND ANY
%%% EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
%%% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%%% DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
%%% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
%%% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
%%% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
%%% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%%% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
%%% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%%
%%%----------------------------------------------------------------------

-module(srtp_test).

% All data within this test is taken from Appendix A. RFC 3711
-include("srtp.hrl").
-include("rtp.hrl").
-include_lib("eunit/include/eunit.hrl").

srtp_test_() ->
	Header = <<128,110,92,186,80,104,29,229,92,98,21,153>>, % 16#806e5cba50681de55c621599
	Payload = <<"pseudorandomness is the next best thing">>, % 70736575646f72616e646f6d6e657373 20697320746865206e65787420626573 74207468696e67
	EncryptedPayload = <<16#019ce7a26e7854014a6366aa95d4eefd:128, 16#1ad4172a14f9faf455b7f1d4b62bd08f:128, 16#562c0eef7c4802:56>>,
	Rtp = #rtp{
		padding = 0,
		marker = 0,
		payload_type = 110,
		sequence_number = 23738,
		timestamp = 1349000677,
		ssrc = 1549931929,
		csrcs = [],
		extension = null,
		payload = Payload
	},
	Roc = 16#d462564a,
	Key = 16#234829008467be186c3de14aae72d62c,
	Salt = 16#32f2870d,
%	{ok, FdA} = gen_udp:open(0, [{active, false}, binary]),
%	{ok, FdB} = gen_udp:open(0, [{active, false}, binary]),
%	{setup,
%		fun() -> true end,
%		fun (_) -> gen_udp:close(FdA),  gen_udp:close(FdB) end,
%		[]
%	}.
	[].
srtp_computeIV_test_() ->
	MasterSalt = <<16#0EC675AD498AFEEBB6960B3AABE6:112>>,
	[

		{"Test IV generation (label #0 - RTP session encryption key)",
			fun() -> ?assertEqual(<<16#0EC675AD498AFEEBB6960B3AABE60000:128>>,
						srtp:computeIV(MasterSalt, ?SRTP_LABEL_RTP_ENCR, 0, 0)) end
		},
		{"Test IV generation (label #1 - RTP session authentication key)",
			fun() -> ?assertEqual(<<16#0EC675AD498AFEEAB6960B3AABE60000:128>>,
						srtp:computeIV(MasterSalt, ?SRTP_LABEL_RTP_AUTH, 0, 0)) end
		},
		{"Test IV generation (label #2 - RTP session salt)",
			fun() -> ?assertEqual(<<16#0EC675AD498AFEE9B6960B3AABE60000:128>>,
						srtp:computeIV(MasterSalt, ?SRTP_LABEL_RTP_SALT, 0, 0)) end
		}

	].

srtp_derive_key_test_() ->
	MasterKey = <<16#E1F97A0D3E018BE0D64FA32C06DE4139:128>>,
	MasterSalt = <<16#0EC675AD498AFEEBB6960B3AABE6:112>>,

	Cipher0 = <<16#C61E7A93744F39EE10734AFE3FF7A087:128>>,
	Cipher1 = <<16#CEBE321F6FF7716B6FD4AB49AF256A15:128>>,
	Cipher2 = <<16#30CBBC08863D8C85D49DB34A9AE17AC6:128>>,
	%<<CipherSalt:112, _/binary>> = Cipher2,
	[
		{"Test RTP session encryption key generation (Label #0)",
			fun() -> ?assertEqual(Cipher0, srtp:derive_key(MasterKey, MasterSalt, ?SRTP_LABEL_RTP_ENCR, 0, 0)) end
		},
		{"Test RTP session authentication key generation (Label #1)",
			fun() -> ?assertEqual(Cipher1, srtp:derive_key(MasterKey, MasterSalt, ?SRTP_LABEL_RTP_AUTH, 0, 0)) end
		},
		{"Test RTP session salt key generation (Label #2)",
			fun() -> ?assertEqual(Cipher2, srtp:derive_key(MasterKey, MasterSalt, ?SRTP_LABEL_RTP_SALT, 0, 0)) end
		},
		{"Simple RTP session auth key generation #0",
			fun() -> ?assertEqual(<<16#CEBE321F6FF7716B6FD4AB49AF256A15:128>>,
						crypto:aes_ctr_encrypt(MasterKey, <<16#0EC675AD498AFEEAB6960B3AABE60000:128>>, <<0:128>>)) end
		},
		{"Simple RTP session auth key generation #1",
			fun() -> ?assertEqual(<<16#6D38BAA48F0A0ACF3C34E2359E6CDBCE:128>>,
						crypto:aes_ctr_encrypt(MasterKey, <<16#0EC675AD498AFEEAB6960B3AABE60001:128>>, <<0:128>>)) end
		},
		{"Simple RTP session auth key generation #2",
			fun() -> ?assertEqual(<<16#E049646C43D9327AD175578EF7227098:128>>,
						crypto:aes_ctr_encrypt(MasterKey, <<16#0EC675AD498AFEEAB6960B3AABE60002:128>>, <<0:128>>)) end
		},
		{"Simple RTP session auth key generation #3",
			fun() -> ?assertEqual(<<16#6371C10C9A369AC2F94A8C5FBCDDDC25:128>>,
						crypto:aes_ctr_encrypt(MasterKey, <<16#0EC675AD498AFEEAB6960B3AABE60003:128>>, <<0:128>>)) end
		},
		{"Simple RTP session auth key generation #4",
			fun() -> ?assertEqual(<<16#6D6E919A48B610EF17C2041E47403576:128>>,
						crypto:aes_ctr_encrypt(MasterKey, <<16#0EC675AD498AFEEAB6960B3AABE60004:128>>, <<0:128>>)) end
		},
		{"Simple RTP session auth key generation #5",
			fun() -> ?assertMatch(<<16#6B68642C59BBFC2F34DB60DBDFB2:112, _/binary>>,
						crypto:aes_ctr_encrypt(MasterKey, <<16#0EC675AD498AFEEAB6960B3AABE60005:128>>, <<0:128>>)) end
		}
	].
