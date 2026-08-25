<?php

namespace Tests\Feature;

use App\Models\InventoryItem;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SaleInventoryIntegrationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Shop $shop;
    protected InventoryItem $inventoryItem;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create([
            'name' => 'Integration Test Shop',
            'phone' => '9876543210',
            'address' => 'Test Street',
        ]);

        $this->user = User::create([
            'shop_id' => $this->shop->id,
            'name' => 'Shop Owner',
            'email' => 'owner@test.com',
            'mobile' => '9876543210',
            'password' => bcrypt('password'),
        ]);

        $this->customer = \App\Models\Customer::create([
            'shop_id' => $this->shop->id,
            'name' => 'Integration Customer',
            'mobile' => '9876543210',
        ]);

        $this->inventoryItem = InventoryItem::create([
            'shop_id' => $this->shop->id,
            'name' => 'iPhone 13 Cover',
            'category' => 'Covers',
            'item_type' => 'accessory',
            'purchase_price' => 150.00,
            'selling_price' => 299.00,
            'current_stock' => 250,
            'minimum_stock' => 10,
            'unit' => 'pcs',
            'is_active' => true,
        ]);
    }

    /** 1. Create sale using inventory item */
    public function test_create_sale_using_inventory_item(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'discount' => 0,
            'tax_amount' => 0,
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'iPhone 13 Cover',
                    'item_type' => 'accessory',
                    'quantity' => 1,
                    'unit_price' => 299.00,
                    'cost_price' => 150.00,
                    'discount' => 0,
                ],
            ],
            'payment_amount' => 299.00,
            'payment_method' => 'cash',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true);
    }

    /** 2 & 3. Verify stock decreases automatically & stock movement created */
    public function test_stock_decreases_and_movement_created(): void
    {
        $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'iPhone 13 Cover',
                    'quantity' => 2,
                    'unit_price' => 299.00,
                ],
            ],
        ]);

        $this->assertDatabaseHas('inventory_items', [
            'id' => $this->inventoryItem->id,
            'current_stock' => 248, // 250 - 2
        ]);

        $this->assertDatabaseHas('stock_movements', [
            'inventory_item_id' => $this->inventoryItem->id,
            'movement_type' => 'sale',
            'quantity' => -2,
        ]);
    }

    /** 4 & 5. Try selling more than available stock - Rejected & Rollback */
    public function test_selling_more_than_available_stock_rejected(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'iPhone 13 Cover',
                    'quantity' => 300, // Available: 250
                    'unit_price' => 299.00,
                ],
            ],
        ]);

        $response->assertStatus(500)
            ->assertJsonPath('success', false);

        // Verify stock remains untouched (atomic rollback)
        $this->assertDatabaseHas('inventory_items', [
            'id' => $this->inventoryItem->id,
            'current_stock' => 250,
        ]);

        $this->assertEquals(0, Sale::count());
    }

    /** 6 & 7. Sell out-of-stock item - Rejected */
    public function test_sell_out_of_stock_item_rejected(): void
    {
        $this->inventoryItem->update(['current_stock' => 0]);

        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'iPhone 13 Cover',
                    'quantity' => 1,
                    'unit_price' => 299.00,
                ],
            ],
        ]);

        $response->assertStatus(500);
    }

    /** 8 & 9. Create Quick Item sale - Does NOT change inventory stock */
    public function test_quick_item_sale_does_not_change_stock(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'inventory_item_id' => null,
                    'product_name' => 'Screen Guard',
                    'item_type' => 'accessory',
                    'quantity' => 5,
                    'unit_price' => 100.00,
                ],
            ],
        ]);

        $response->assertStatus(201);

        // Inventory stock must remain 250
        $this->assertDatabaseHas('inventory_items', [
            'id' => $this->inventoryItem->id,
            'current_stock' => 250,
        ]);

        $this->assertEquals(0, StockMovement::count());
    }

    /** 10, 11 & 12. Snapshot immutability after inventory price change */
    public function test_invoice_snapshot_remains_unchanged_when_inventory_price_changes(): void
    {
        $res = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/sales', [
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id,
                    'product_name' => 'iPhone 13 Cover',
                    'quantity' => 1,
                    'unit_price' => 299.00,
                    'cost_price' => 150.00,
                ],
            ],
        ]);

        $saleId = $res->json('data.id');

        // Owner changes inventory item price tomorrow
        $this->inventoryItem->update([
            'selling_price' => 349.00,
            'purchase_price' => 180.00,
        ]);

        // Yesterday's invoice item must still have unit_price = 299 & cost_price = 150
        $this->assertDatabaseHas('sale_items', [
            'sale_id' => $saleId,
            'unit_price' => 299.00,
            'cost_price' => 150.00,
        ]);
    }

    /** 17. Multi-tenant shop isolation: Shop A cannot sell Shop B inventory */
    public function test_shop_a_cannot_access_shop_b_inventory_in_sales(): void
    {
        $shopB = Shop::create(['name' => 'Shop B', 'phone' => '1111111111']);
        $userB = User::create([
            'shop_id' => $shopB->id,
            'name' => 'Owner B',
            'email' => 'b@test.com',
            'mobile' => '1111111111',
            'password' => bcrypt('password'),
        ]);

        // User B tries to sell Shop A's inventory item
        $response = $this->actingAs($userB, 'sanctum')->postJson('/api/v1/sales', [
            'sale_type' => 'quick',
            'customer_id' => $this->customer->id,
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'inventory_item_id' => $this->inventoryItem->id, // Belongs to Shop A
                    'product_name' => 'Hacked Item',
                    'quantity' => 1,
                    'unit_price' => 299.00,
                ],
            ],
        ]);

        $response->assertStatus(422);
    }
}