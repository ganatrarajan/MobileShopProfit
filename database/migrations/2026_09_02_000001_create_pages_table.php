<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('pages')) {
            Schema::create('pages', function (Blueprint $table) {
                $table->id();
                $table->string('slug')->unique();
                $table->string('title');
                $table->text('meta_description')->nullable();
                $table->longText('content');
                $table->string('status')->default('published'); // published, draft
                $table->timestamps();
            });

            // Seed default dynamic pages
            DB::table('pages')->insert([
                [
                    'slug'             => 'privacy-policy',
                    'title'            => 'Privacy Policy',
                    'meta_description' => 'Privacy Policy for Mobile Profits SaaS platform and Mobile Application.',
                    'content'          => '<h1>Privacy Policy for Mobile Profits</h1>' .
                                          '<p>Last Updated: September 2, 2026</p>' .
                                          '<p>Welcome to <strong>Mobile Profits</strong>. Your privacy is critically important to us. This Privacy Policy document describes how Mobile Profits collects, uses, stores, and protects customer, shop management, repair tracking, and financial record data when you use our web platform and mobile application.</p>' .
                                          '<h2>1. Information We Collect</h2>' .
                                          '<p>We collect information necessary to provide shop management, billing, inventory, repair card, and financial analytics services, including:</p>' .
                                          '<ul>' .
                                          '<li><strong>Shop & Account Details:</strong> Shop Name, Owner Name, Email Address, Phone Number, Business Address, GSTIN/Tax ID.</li>' .
                                          '<li><strong>Customer Information:</strong> Customer Name, Phone Number, Email, Device Repair History, and Invoice Details entered by shop owners.</li>' .
                                          '<li><strong>Device & IMEI Records:</strong> Model, Serial/IMEI Numbers, Physical Condition, and Repair Job Notes.</li>' .
                                          '<li><strong>Transaction & Financial Logs:</strong> Billing records, expense entries, payment receipts, and technician payouts for profit calculation.</li>' .
                                          '</ul>' .
                                          '<h2>2. How We Use Your Information</h2>' .
                                          '<p>We process your data strictly to deliver platform services, calculate Profit Intelligence analytics, process subscriptions, send invoice alerts, and maintain security logs.</p>' .
                                          '<h2>3. Data Security & Storage</h2>' .
                                          '<p>All data is encrypted in transit using industry-standard SSL/TLS protocols and stored securely in cloud server infrastructure with automated backups and role-based access control.</p>' .
                                          '<h2>4. Third-Party Sharing</h2>' .
                                          '<p>Mobile Profits does NOT sell, rent, or trade user data to third parties. We share data only with authorized payment gateways (e.g. Razorpay) strictly for processing subscription payments.</p>' .
                                          '<h2>5. Your Rights & Account Deletion</h2>' .
                                          '<p>You have the right to inspect, correct, or request deletion of your account and associated shop records at any time via our <a href="/delete-account">Account Deletion Page</a> or by contacting support.</p>' .
                                          '<h2>6. Contact Us</h2>' .
                                          '<p>If you have questions regarding this Privacy Policy, contact us at <strong>support@mobileprofits.com</strong> or call <strong>+91 98765 43210</strong>.</p>',
                    'status'           => 'published',
                    'created_at'       => now(),
                    'updated_at'       => now(),
                ],
                [
                    'slug'             => 'terms-and-conditions',
                    'title'            => 'Terms & Conditions',
                    'meta_description' => 'Terms and Conditions governing the use of Mobile Profits shop management application.',
                    'content'          => '<h1>Terms & Conditions</h1>' .
                                          '<p>Last Updated: September 2, 2026</p>' .
                                          '<p>Please read these Terms & Conditions carefully before using the Mobile Profits SaaS application or Mobile App.</p>' .
                                          '<h2>1. Account Registration</h2>' .
                                          '<p>You must provide accurate business details upon registration. You are responsible for safeguarding your login credentials and maintaining control over shop staff accounts.</p>' .
                                          '<h2>2. SaaS Subscriptions & Billing</h2>' .
                                          '<p>Mobile Profits operates on a subscription fee model (Monthly or Annual). Access to premium features is granted upon active paid subscription status.</p>' .
                                          '<h2>3. Permitted Usage</h2>' .
                                          '<p>Mobile Profits is intended solely for mobile shop inventory, customer invoice, repair job card, technician tracking, and profit management. You agree not to misuse the platform or engage in unlawful activities.</p>' .
                                          '<h2>4. Service Availability & Support</h2>' .
                                          '<p>We strive for 99.9% uptime. Scheduled maintenance will be communicated in advance. Support is available during official working hours.</p>' .
                                          '<h2>5. Limitation of Liability</h2>' .
                                          '<p>Mobile Profits is not liable for indirect loss of profit or data resulting from user negligence, incorrect inventory entries, or unverified manual calculations.</p>',
                    'status'           => 'published',
                    'created_at'       => now(),
                    'updated_at'       => now(),
                ],
                [
                    'slug'             => 'refund-policy',
                    'title'            => 'Refund & Cancellation Policy',
                    'meta_description' => 'Refund and subscription cancellation rules for Mobile Profits.',
                    'content'          => '<h1>Refund & Cancellation Policy</h1>' .
                                          '<p>Last Updated: September 2, 2026</p>' .
                                          '<p>At Mobile Profits, customer satisfaction is our top priority. Please review our subscription refund and cancellation rules below.</p>' .
                                          '<h2>1. Free Trial</h2>' .
                                          '<p>Every new mobile shop receives a free trial period to evaluate all feature modules before purchasing a subscription plan.</p>' .
                                          '<h2>2. Subscription Cancellations</h2>' .
                                          '<p>You can cancel your subscription renewal at any time through your account settings or by contacting our support team. Your active subscription will remain accessible until the end of your billing cycle.</p>' .
                                          '<h2>3. Refund Eligibility</h2>' .
                                          '<p>Refund requests submitted within 7 days of initial subscription purchase will be reviewed on a case-by-case basis. Approved refunds are processed back to the original payment method within 5-7 business days.</p>' .
                                          '<h2>4. Contact Support</h2>' .
                                          '<p>For refund assistance or billing queries, email <strong>support@mobileprofits.com</strong> or call <strong>+91 98765 43210</strong>.</p>',
                    'status'           => 'published',
                    'created_at'       => now(),
                    'updated_at'       => now(),
                ],
                [
                    'slug'             => 'delete-account',
                    'title'            => 'Account Deletion Policy',
                    'meta_description' => 'Instructions and request procedure for deleting your Mobile Profits user account.',
                    'content'          => '<h1>Account Deletion Policy & Request</h1>' .
                                          '<p>Last Updated: September 2, 2026</p>' .
                                          '<p>We respect your privacy and data autonomy. If you wish to delete your Mobile Profits shop account and purge your shop records, please follow the steps outlined below.</p>' .
                                          '<h2>What Information Will Be Deleted?</h2>' .
                                          '<ul>' .
                                          '<li>Shop owner profile credentials (Name, Email, Mobile).</li>' .
                                          '<li>Shop configuration details and staff logins.</li>' .
                                          '<li>Cached device repair photos and attached document files.</li>' .
                                          '</ul>' .
                                          '<h2>Data Retention Notice</h2>' .
                                          '<p>Financial transaction summaries and invoice records may be retained in anonymized format for accounting compliance as required by applicable tax laws.</p>' .
                                          '<h2>Processing Timeline</h2>' .
                                          '<p>Account deletion requests are processed within 7 business days following identity verification.</p>',
                    'status'           => 'published',
                    'created_at'       => now(),
                    'updated_at'       => now(),
                ],
            ]);
        }

        // Ensure default settings exist in system_settings
        if (Schema::hasTable('system_settings')) {
            $defaultSettings = [
                ['key' => 'app_name', 'value' => 'Mobile Profits'],
                ['key' => 'support_email', 'value' => 'support@mobileprofits.com'],
                ['key' => 'support_phone', 'value' => '+91 98765 43210'],
                ['key' => 'whatsapp_number', 'value' => '+91 98765 43210'],
                ['key' => 'support_hours', 'value' => 'Mon - Sat: 9:00 AM - 8:00 PM IST'],
                ['key' => 'android_app_url', 'value' => '#'],
                ['key' => 'ios_app_url', 'value' => '#'],
                ['key' => 'copyright_text', 'value' => '© 2026 Mobile Profits. All rights reserved.'],
            ];

            foreach ($defaultSettings as $setting) {
                DB::table('system_settings')->updateOrInsert(
                    ['key' => $setting['key']],
                    ['value' => $setting['value'], 'updated_at' => now()]
                );
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pages');
    }
};
