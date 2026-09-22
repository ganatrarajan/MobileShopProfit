<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'msg91' => [
        'auth_key'        => env('MSG91_AUTH_KEY'),
        'widget_id'       => env('MSG91_WIDGET_ID'),
        'template_id'     => env('MSG91_OTP_TEMPLATE_ID'),
        'enabled'         => env('MSG91_ENABLED', true),
        'otp_expiry'      => (int) env('MSG91_OTP_EXPIRY', 300),
        'resend_cooldown' => (int) env('MSG91_OTP_RESEND_COOLDOWN', 60),
        'max_attempts'    => (int) env('MSG91_OTP_MAX_ATTEMPTS', 5),
    ],

];
