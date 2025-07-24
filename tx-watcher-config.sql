
insert into ogmios_checkpoints (hash, block_no, slot, filter_type) values 
('28f136a8fecf188fcbce7c69711a9aa03ed69c4c15828746d00cb0cbe2de29c1', 10769480, 133423449, 'DEFAULT'),
('28f136a8fecf188fcbce7c69711a9aa03ed69c4c15828746d00cb0cbe2de29c1', 10769480, 133423449, 'CERTIFICATES'),
('28f136a8fecf188fcbce7c69711a9aa03ed69c4c15828746d00cb0cbe2de29c1', 10769480, 133423449, 'PROPOSALS'),
('28f136a8fecf188fcbce7c69711a9aa03ed69c4c15828746d00cb0cbe2de29c1', 10769480, 133423449, 'VOTES');


INSERT INTO api_keys (api_key,service_name,msg_type) VALUES
	('d558d056fad37f98abf07f6e0dbd7ba8','DREP TXN CONSUMER','DRepTxnMsgType'),
	('f5c2764eebb66d8dc11ed0757c9f3f23','DREP CERTIFICATE CONSUMER','DRepCertificateMsgType'),
	('134d0950dd6c0ab6812c9e8005777a84','DREP VOTE CONSUMER','DRepVoteMsgType'),
	('de782e4649decda865fdab0384e0a2cb','DREP PROPOSAL CONSUMER','DRepProposalMsgType'),
	('12963e63251a1abc','Cardano BFF','CardanoBffMsgType'),
	('7727462d074a5045','Fix Lending Indexer','FixedLendingIndexerMsgType');


INSERT INTO event_configs (wallet_address,network_id,api_key) VALUES
	('addr1q8jy6jx2th2khjt2tk6pwzm5l5al5fpqquhp7tn852s9yxrw2aappdz98nah303sy0dc3p83x4hewv5z5c44q2sfqgqq2w8qrk', 42, 'd558d056fad37f98abf07f6e0dbd7ba8'),
	('addr_test1vztc80na8320zymhjekl40yjsnxkcvhu58x59mc2fuwvgkc332vxv', 42, '7727462d074a5045');


