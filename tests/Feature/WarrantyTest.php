<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Device;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\User;
use App\Models\Warranty;
use App\Models\WarrantyClaim;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WarrantyTest extends TestCase
{
    use RefreshDatabase;

    protected function setupShopAndUser(): array
    {
        $shop = Shop::create([
            'name' => 'Warranty Mobile Shop',
            'phone' => '9876543210',
            'owner_name' => 'Warranty Owner',
        ]);

        $user = User::create([
            'shop_id' => $shop->id,
            'name' => 'Warranty Owner',
            'mobile' => '9876543210',
            'role' => 'owner',
            'password' => bcrypt('password'),
        ]);

        return [$shop, $user];
    }

    public function test_can_create_sale_and_repair_warranty_with_custom_or_preset_duration()
    {
        [$shop, $user] = $this->setupShopAndUser();

        $customer = Customer::create([
            'shop_id' => $shop->id,
            'name' => 'Rahul Sharma',
            'mobile' => '9777777777',
        ]);

        $device = Device::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer->id,
            'device_type' => 'Mobile',
            'brand' => 'Samsung',
            'model' => 'Galaxy S24',
            'imei_1' => '351111222233334',
        ]);

        $sale = Sale::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'invoice_number' => 'INV-000001',
            'sale_date' => now()->toDateString(),
            'subtotal' => 55000,
            'grand_total' => 55000,
            'amount_paid' => 55000,
            'amount_due' => 0,
            'created_by' => $user->id,
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/warranties', [
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'sale_id' => $sale->id,
            'warranty_type' => 'sale',
            'duration_days' => 365,
            'warranty_terms' => 'Standard 1 year manufacturer warranty covering manufacturing defects.',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.warranty_number', 'WAR-000001')
            ->assertJsonPath('data.warranty_type', 'sale')
            ->assertJsonPath('data.duration_days', 365)
            ->assertJsonPath('data.status', 'active');
    }

    public function test_dynamic_warranty_status_calculation()
    {
        [$shop, $user] = $this->setupShopAndUser();

        $customer = Customer::create(['shop_id' => $shop->id, 'name' => 'Test', 'mobile' => '9000000000']);
        $device = Device::create(['shop_id' => $shop->id, 'customer_id' => $customer->id, 'device_type' => 'Mobile', 'brand' => 'A', 'model' => 'B']);

        // Expired warranty (ended 10 days ago)
        $expiredWarranty = Warranty::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'warranty_number' => 'WAR-000001',
            'warranty_type' => 'repair',
            'warranty_start_date' => Carbon::now()->subDays(40)->toDateString(),
            'warranty_end_date' => Carbon::now()->subDays(10)->toDateString(),
            'duration_days' => 30,
            'status' => 'active',
            'created_by' => $user->id,
        ]);

        $this->assertEquals('expired', $expiredWarranty->computed_status);
        $this->assertLessThan(0, $expiredWarranty->days_remaining);

        // Expiring Soon warranty (ends in 3 days)
        $expiringSoonWarranty = Warranty::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'warranty_number' => 'WAR-000002',
            'warranty_type' => 'repair',
            'warranty_start_date' => Carbon::now()->subDays(27)->toDateString(),
            'warranty_end_date' => Carbon::now()->addDays(3)->toDateString(),
            'duration_days' => 30,
            'status' => 'active',
            'created_by' => $user->id,
        ]);

        $this->assertEquals('expiring_soon', $expiringSoonWarranty->computed_status);
    }

    public function test_can_create_warranty_claim_and_transition_status()
    {
        [$shop, $user] = $this->setupShopAndUser();

        $customer = Customer::create(['shop_id' => $shop->id, 'name' => 'Karan', 'mobile' => '9666666666']);
        $device = Device::create(['shop_id' => $shop->id, 'customer_id' => $customer->id, 'device_type' => 'Mobile', 'brand' => 'Apple', 'model' => 'iPhone 13']);

        $warranty = Warranty::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'warranty_number' => 'WAR-000001',
            'warranty_type' => 'repair',
            'warranty_start_date' => Carbon::today()->toDateString(),
            'warranty_end_date' => Carbon::today()->addDays(30)->toDateString(),
            'duration_days' => 30,
            'status' => 'active',
            'created_by' => $user->id,
        ]);

        // File a claim
        $claimResponse = $this->actingAs($user, 'sanctum')->postJson("/api/v1/warranties/{$warranty->id}/claims", [
            'complaint' => 'Screen flicker issue after 10 days of repair',
        ]);

        $claimResponse->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.claim_number', 'CLM-000001')
            ->assertJsonPath('data.claim_status', 'open');

        $claimId = $claimResponse->json('data.id');

        // Transition status to Resolved
        $updateResponse = $this->actingAs($user, 'sanctum')->putJson("/api/v1/warranty-claims/{$claimId}", [
            'claim_status' => 'resolved',
            'resolution' => 'Replaced display connector cable under rework warranty free of cost.',
        ]);

        $updateResponse->assertStatus(200)
            ->assertJsonPath('data.claim_status', 'resolved')
            ->assertJsonPath('data.resolution', 'Replaced display connector cable under rework warranty free of cost.');
    }

    public function test_shop_isolation_prevents_access_to_other_shop_warranties()
    {
        [$shopA, $userA] = $this->setupShopAndUser();

        $shopB = Shop::create(['name' => 'Shop B', 'phone' => '9555555555', 'owner_name' => 'Owner B']);
        $userB = User::create(['shop_id' => $shopB->id, 'name' => 'User B', 'mobile' => '9555555555', 'role' => 'owner', 'password' => bcrypt('pass')]);

        $customerA = Customer::create(['shop_id' => $shopA->id, 'name' => 'A', 'mobile' => '9000000001']);
        $deviceA = Device::create(['shop_id' => $shopA->id, 'customer_id' => $customerA->id, 'device_type' => 'Mobile', 'brand' => 'X', 'model' => 'Y']);

        $warrantyA = Warranty::create([
            'shop_id' => $shopA->id,
            'customer_id' => $customerA->id,
            'device_id' => $deviceA->id,
            'warranty_number' => 'WAR-000001',
            'warranty_type' => 'sale',
            'warranty_start_date' => Carbon::today()->toDateString(),
            'warranty_end_date' => Carbon::today()->addDays(30)->toDateString(),
            'duration_days' => 30,
            'status' => 'active',
            'created_by' => $userA->id,
        ]);

        // User B attempts to view Shop A's warranty
        $this->actingAs($userB, 'sanctum')->getJson("/api/v1/warranties/{$warrantyA->id}")
            ->assertStatus(404);
    }
}