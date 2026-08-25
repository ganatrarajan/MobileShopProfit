<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\InventoryItem;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class QuickSaleTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Shop $shop;
    protected InventoryItem $inventoryItem;
    protected Customer $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create([
            'name' => 'Quick Sale Shop',
            'phone' => '9876543210',
            'address' => 'Main Market',
        ]);

        $this->user = User::create([
            'shop_id' => $this->shop->id,
            'name' => 'Quick Owner',
            'email' => 'quickowner@test.com',
            'mobile' => '9876543210',
            'password' => bcrypt('password'),
        ]);

        $this->customer = Customer::create([
            'shop_id' => $this->shop->id,
            'name' => 'Existing Customer',
            'mobile' => '9998887776',
        ]);

        $this->inventoryItem = InventoryItem::create([
            'shop_id' => $this->shop->id,
            'name' => 'Fast Charger 25W',
            'category' => 'Chargers',
            'item_type' => 'accessory',
            'purchase_price' => 200.00,
            'selling_price' => 499.00,
            'current_stock' => 50,
            'minimum_stock' => 5,
            'unit' => 'pcs',
            'is_active' => true,
        ]);
    }

    /** 1. Quick Sale without customer */
    public function test_quick_sale_without_customer(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'customer_id' => null,
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'Fast Charger 25W',
                    'quantity' => 1,
                    'unit_price' => 499.00,
                ],
            ],
            'payment_amount' => 499.00,
            'payment_method' => 'cash',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.sale_type', 'quick');
    }

    /** 2, 3, 4, 5. Quick Sale with optional name & mobile - No permanent customer created */
    public function test_quick_sale_with_optional_name_and_mobile_no_customer_created(): void
    {
        $customerCountBefore = Customer::count();

        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'customer_name' => 'Amit Sharma',
            'customer_mobile' => '9876500000',
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'Fast Charger 25W',
                    'quantity' => 1,
                    'unit_price' => 499.00,
                ],
            ],
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.customer_name', 'Amit Sharma')
            ->assertJsonPath('data.customer_mobile', '9876500000');

        // Customer table row count must NOT increase
        $this->assertEquals($customerCountBefore, Customer::count());
    }

    /** 6, 7, 8, 9. Quick Sale using inventory item - Decreases stock & logs movement */
    public function test_quick_sale_decreases_inventory_stock_and_logs_movement(): void
    {
        $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'Fast Charger 25W',
                    'quantity' => 3,
                    'unit_price' => 499.00,
                ],
            ],
        ]);

        $this->assertDatabaseHas('inventory_items', [
            'id' => $this->inventoryItem->id,
            'current_stock' => 47, // 50 - 3
        ]);

        $this->assertDatabaseHas('stock_movements', [
            'inventory_item_id' => $this->inventoryItem->id,
            'movement_type' => 'sale',
            'quantity' => -3,
        ]);
    }

    /** 10. Quick Sale with insufficient stock - Rejected */
    public function test_quick_sale_with_insufficient_stock_rejected(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'Fast Charger 25W',
                    'quantity' => 100, // Only 50 available
                    'unit_price' => 499.00,
                ],
            ],
        ]);

        $response->assertStatus(500);

        $this->assertDatabaseHas('inventory_items', [
            'id' => $this->inventoryItem->id,
            'current_stock' => 50,
        ]);
    }

    /** 11. Regular Sale requires customer */
    public function test_regular_sale_requires_customer(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'regular',
            'customer_id' => null,
            'items' => [
                [
                    'product_name' => 'Cover',
                    'quantity' => 1,
                    'unit_price' => 100.00,
                ],
            ],
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['customer_id']);
    }

    /** 12. Mobile phone sale requires customer even if sale_type is quick */
    public function test_mobile_phone_sale_requires_customer(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'customer_id' => null,
            'items' => [
                [
                    'product_name' => 'iPhone 13',
                    'item_type' => 'mobile',
                    'brand' => 'Apple',
                    'model' => 'iPhone 13',
                    'quantity' => 1,
                    'unit_price' => 55000.00,
                ],
            ],
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['customer_id']);
    }

    /** 16, 17, 18. Quick Sale appears in sales history & filterable by sale_type */
    public function test_quick_sale_appears_in_sales_history_and_filters(): void
    {
        // 1 Quick Sale
        $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'customer_name' => 'Rohan',
            'items' => [['product_name' => 'Cable', 'quantity' => 1, 'unit_price' => 150.00]],
        ]);

        // 1 Regular Sale
        $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'regular',
            'customer_id' => $this->customer->id,
            'items' => [['product_name' => 'Adapter', 'quantity' => 1, 'unit_price' => 500.00]],
        ]);

        // Filter Quick Sales
        $responseQuick = $this->actingAs($this->user, 'sanctum')->getJson('/api/v1/sales?sale_type=quick');
        $responseQuick->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.sale_type', 'quick');

        // Filter Regular Sales
        $responseReg = $this->actingAs($this->user, 'sanctum')->getJson('/api/v1/sales?sale_type=regular');
        $responseReg->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.sale_type', 'regular');
    }

    /** 21. Shop A cannot access Shop B sales */
    public function test_shop_a_cannot_access_shop_b_sales(): void
    {
        $shopB = Shop::create(['name' => 'Shop B', 'phone' => '1111111111']);
        $userB = User::create([
            'shop_id' => $shopB->id,
            'name' => 'Owner B',
            'email' => 'b2@test.com',
            'mobile' => '1111111111',
            'password' => bcrypt('password'),
        ]);

        $res = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'items' => [['product_name' => 'Cable', 'quantity' => 1, 'unit_price' => 150.00]],
        ]);

        $saleId = $res->json('data.id');

        // User B tries to view Shop A's sale
        $responseB = $this->actingAs($userB, 'sanctum')->getJson("/api/v1/sales/{$saleId}");
        $responseB->assertStatus(404);
    }
}