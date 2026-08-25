<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Device;
use App\Models\Repair;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RepairTest extends TestCase
{
    use RefreshDatabase;

    protected function setupShopAndUser(): array
    {
        $shop = Shop::create([
            'name' => 'Repair Mobile Shop',
            'phone' => '9876543210',
            'owner_name' => 'Owner User',
        ]);

        $user = User::create([
            'shop_id' => $shop->id,
            'name' => 'Owner User',
            'mobile' => '9876543210',
            'role' => 'owner',
            'password' => bcrypt('password'),
        ]);

        return [$shop, $user];
    }

    public function test_can_create_repair_job_card_with_customer_and_device()
    {
        [$shop, $user] = $this->setupShopAndUser();

        $customer = Customer::create([
            'shop_id' => $shop->id,
            'name' => 'Vikram Patel',
            'mobile' => '9898989898',
        ]);

        $device = Device::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer->id,
            'device_type' => 'Mobile',
            'brand' => 'Apple',
            'model' => 'iPhone 13',
            'imei_1' => '359999888877771',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/repairs', [
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'problem_description' => 'Display broken and touch non-functional',
            'device_condition' => ['Screen damaged', 'Body scratches'],
            'accessories_received' => ['Charger', 'Cover'],
            'estimated_cost' => 5000,
            'payment_amount' => 1000,
            'payment_method' => 'upi',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.job_number', 'JOB-000001')
            ->assertJsonPath('data.repair_status', 'received')
            ->assertJsonPath('data.estimated_cost', 5000)
            ->assertJsonPath('data.amount_paid', 1000)
            ->assertJsonPath('data.amount_due', 4000);
    }

    public function test_cannot_create_repair_for_device_belonging_to_another_customer()
    {
        [$shop, $user] = $this->setupShopAndUser();

        $customer1 = Customer::create([
            'shop_id' => $shop->id,
            'name' => 'Customer One',
            'mobile' => '9111111111',
        ]);

        $customer2 = Customer::create([
            'shop_id' => $shop->id,
            'name' => 'Customer Two',
            'mobile' => '9222222222',
        ]);

        $deviceCustomer1 = Device::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer1->id,
            'device_type' => 'Mobile',
            'brand' => 'Samsung',
            'model' => 'Galaxy S21',
        ]);

        // Attempt to create repair for Customer 2 using Customer 1's device
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/repairs', [
            'customer_id' => $customer2->id,
            'device_id' => $deviceCustomer1->id,
            'problem_description' => 'Battery drain issue',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_can_update_repair_status_parts_and_collect_payments()
    {
        [$shop, $user] = $this->setupShopAndUser();

        $customer = Customer::create([
            'shop_id' => $shop->id,
            'name' => 'Amit Shah',
            'mobile' => '9333333333',
        ]);

        $device = Device::create([
            'shop_id' => $shop->id,
            'customer_id' => $customer->id,
            'device_type' => 'Mobile',
            'brand' => 'OnePlus',
            'model' => 'OnePlus 9',
        ]);

        $repairResponse = $this->actingAs($user, 'sanctum')->postJson('/api/v1/repairs', [
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'problem_description' => 'Charging port damaged',
            'estimated_cost' => 1500,
        ]);

        $repairId = $repairResponse->json('data.id');

        // Add part
        $this->actingAs($user, 'sanctum')->postJson("/api/v1/repairs/{$repairId}/parts", [
            'part_name' => 'Type-C Charging Sub-board',
            'quantity' => 1,
            'selling_price' => 800,
        ])->assertStatus(201);

        // Update status to Repairing
        $this->actingAs($user, 'sanctum')->patchJson("/api/v1/repairs/{$repairId}/status", [
            'repair_status' => 'repairing',
        ])->assertStatus(200)->assertJsonPath('data.repair_status', 'repairing');

        // Collect payment
        $this->actingAs($user, 'sanctum')->postJson("/api/v1/repairs/{$repairId}/payments", [
            'amount' => 1500,
            'payment_method' => 'cash',
        ])->assertStatus(201)->assertJsonPath('data.amount_due', 0);

        // Mark Delivered
        $this->actingAs($user, 'sanctum')->patchJson("/api/v1/repairs/{$repairId}/status", [
            'repair_status' => 'delivered',
        ])->assertStatus(200)->assertJsonPath('data.repair_status', 'delivered');
    }

    public function test_shop_isolation_prevents_access_to_other_shop_repairs()
    {
        [$shopA, $userA] = $this->setupShopAndUser();

        $shopB = Shop::create([
            'name' => 'Other Shop',
            'phone' => '9444444444',
            'owner_name' => 'Other Owner',
        ]);

        $userB = User::create([
            'shop_id' => $shopB->id,
            'name' => 'Other Owner',
            'mobile' => '9444444444',
            'role' => 'owner',
            'password' => bcrypt('password'),
        ]);

        $customerA = Customer::create(['shop_id' => $shopA->id, 'name' => 'A', 'mobile' => '9000000001']);
        $deviceA = Device::create(['shop_id' => $shopA->id, 'customer_id' => $customerA->id, 'device_type' => 'Mobile', 'brand' => 'X', 'model' => 'Y']);

        $repairResponse = $this->actingAs($userA, 'sanctum')->postJson('/api/v1/repairs', [
            'customer_id' => $customerA->id,
            'device_id' => $deviceA->id,
            'problem_description' => 'Test',
        ]);

        $repairId = $repairResponse->json('data.id');

        // User B tries to access Shop A's repair
        $this->actingAs($userB, 'sanctum')->getJson("/api/v1/repairs/{$repairId}")
            ->assertStatus(404);
    }
}