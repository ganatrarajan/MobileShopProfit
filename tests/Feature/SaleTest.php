<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Device;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SaleTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Shop $shop;
    protected Customer $customer;
    protected Device $device;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create([
            'name' => 'Mobile Hub',
            'phone' => '9876543210',
            'address' => 'Station Road',
        ]);

        $this->user = User::create([
            'shop_id' => $this->shop->id,
            'name' => 'Store Manager',
            'email' => 'manager@mobilehub.com',
            'mobile' => '9876543210',
            'password' => bcrypt('password'),
        ]);

        $this->customer = Customer::create([
            'shop_id' => $this->shop->id,
            'name' => 'Rahul Verma',
            'mobile' => '9876543210',
        ]);

        $this->device = Device::create([
            'shop_id' => $this->shop->id,
            'customer_id' => $this->customer->id,
            'brand' => 'Apple',
            'model' => 'iPhone 13',
            'serial_number' => 'DNPG12345678',
        ]);
    }

    public function test_can_create_walk_in_sale_without_customer_or_device(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'discount' => 0,
            'tax_amount' => 0,
            'items' => [
                [
                    'product_name' => 'Tempered Glass',
                    'item_type' => 'accessory',
                    'quantity' => 2,
                    'unit_price' => 150.00,
                    'discount' => 0,
                    'tax_amount' => 0,
                ],
            ],
            'payment_amount' => 300.00,
            'payment_method' => 'cash',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.payment_status', 'paid');
    }

    public function test_sale_with_item_discount_calculates_correct_grand_total_and_paid_status(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'product_name' => 'Phone Case',
                    'item_type' => 'accessory',
                    'quantity' => 1,
                    'unit_price' => 500.00,
                    'discount' => 50.00,
                ],
            ],
            'payment_amount' => 450.00,
            'payment_method' => 'upi',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.grand_total', 450)
            ->assertJsonPath('data.payment_status', 'paid');
    }

    public function test_shop_isolation_prevents_access_to_other_shop_sales(): void
    {
        $shopB = Shop::create(['name' => 'Shop B', 'phone' => '1111111111']);
        $userB = User::create([
            'shop_id' => $shopB->id,
            'name' => 'User B',
            'email' => 'userb@test.com',
            'mobile' => '1111111111',
            'password' => bcrypt('password'),
        ]);

        $res = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [['product_name' => 'Case', 'quantity' => 1, 'unit_price' => 100]],
        ]);

        $saleId = $res->json('data.id');

        $responseB = $this->actingAs($userB, 'sanctum')->getJson("/api/v1/sales/{$saleId}");
        $responseB->assertStatus(404);
    }

    public function test_can_delete_sale_invoice(): void
    {
        $res = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [['product_name' => 'Case', 'quantity' => 1, 'unit_price' => 100]],
        ]);

        $saleId = $res->json('data.id');

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson("/api/v1/sales/{$saleId}");
        $response->assertStatus(200);
    }
}