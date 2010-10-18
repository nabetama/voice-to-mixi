#!/usr/bin/env perl
use strict;
use warnings;

use YAML::Tiny;
use WWW::Mixi;
use Web::Scraper;
use Encode;
use File::Basename;

my $default_message = 'test';

# (1) ログイン情報の取得
my $login_info = ( YAML::Tiny->read( 'login_info.yaml' ))->[0];

# (2) ログイン情報の設定
my $mixi = WWW::Mixi->new(
    $login_info->{'username'},
        $login_info->{'password'},
        );

# (3) ログイン
$mixi-> login;

# (4) mixi.jp/recent_voice.plのHTMLを取得する
my $res = $mixi->get('recent_voice.pl');

# (5) スクレイピング情報の設定
my $scraper = scraper {
        process '#voicePost input.#post_key', 'post_key' => '@value';
        process '#voicePost input.#redirect', 'redirect' => '@value';
        process '#voicePost input.#defaultValue', 'default_value' => '@value';
};

# (6) スクレイピング
my $result = $scraper->scrape( $res->content );

# (7) 投稿内容の設定
my $message = shift || $default_message;
$message .= " from " . basename $0; # スクリプト名を末尾につけておく

# (8) 文字化け対応
my $decoded = decode('utf-8', $message );
my $encoded = encode('euc-jp', $decoded );

# (9) $resultに、エンコード済み文字列をbodyというキーを自動生成して追加
$result->{body} = $encoded;

# (10) ボイスの投稿
$res = $mixi->post('add_voice.pl', $result );
