<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Device;
use App\Models\InventoryItem;
use App\Models\Shop;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class InventoryTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Shop $shop;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create([
            'name' => 'Test Mobile Repair Shop',
            'owner_name' => 'John Doe',
            'phone' => '9876543210',
            'address' => '123 Main St',
        ]);

        $this->user = User::create([
            'shop_id' => $this->shop->id,
            'name' => 'Test User',
            'email' => 'testinventory@example.com',
            'mobile' => '9876543210',
            'password' => bcrypt('password123'),
            'role' => 'owner',
        ]);
    }

    public function test_can_create_inventory_item_with_opening_stock(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/v1/inventory', [
                'name' => 'iPhone 13 Display',
                'category' => 'Displays',
                'brand' => 'Apple',
                'model' => 'iPhone 13',
                'item_type' => 'spare_part',
                'purchase_price' => 4500.00,
                'selling_price' => 7000.00,
                'opening_stock' => 10,
                'minimum_stock' => 2,
                'unit' => 'pcs',
                'description' => 'Original OLED Display Combo',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'iPhone 13 Display')
            ->assertJsonPath('data.current_stock', 10)
            ->assertJsonPath('data.stock_value', 45000);

        $itemId = $response->json('data.id');

        $this->assertDatabaseHas('inventory_items', [
            'id' => $itemId,
            'shop_id' => $this->shop->id,
            'current_stock' => 10,
        ]);

        $this->assertDatabaseHas('stock_movements', [
            'inventory_item_id' => $itemId,
            'movement_type' => 'opening_stock',
            'quantity' => 10,
            'unit_cost' => 4500.00,
        ]);
    }

    public function test_can_add_stock_to_inventory_item(): void
    {
        $item = InventoryItem::create([
            'shop_id' => $this->shop->id,
            'name' => 'USB-C Cable',
            'item_type' => 'accessory',
            'purchase_price' => 100.00,
            'selling_price' => 250.00,
            'current_stock' => 5,
            'minimum_stock' => 2,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/v1/inventory/{$item->id}/stock", [
                'quantity' => 10,
                'unit_cost' => 110.00,
                'notes' => 'New shipment batch',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.current_stock', 15);

        $this->assertDatabaseHas('inventory_items', [
            'id' => $item->id,
            'current_stock' => 15,
            'purchase_price' => 110.00,
        ]);

        $this->assertDatabaseHas('stock_movements', [
            'inventory_item_id' => $item->id,
            'movement_type' => 'purchase',
            'quantity' => 10,
            'unit_cost' => 110.00,
        ]);
    }

    public function test_can_adjust_stock_for_damaged_and_return(): void
    {
        $item = InventoryItem::create([
            'shop_id' => $this->shop->id,
            'name' => 'Battery iPhone 11',
            'item_type' => 'spare_part',
            'purchase_price' => 1200.00,
            'selling_price' => 2200.00,
            'current_stock' => 10,
            'minimum_stock' => 3,
        ]);

        // Damaged adjustment (-2)
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/v1/inventory/{$item->id}/adjustment", [
                'adjustment_type' => 'damaged',
                'quantity' => 2,
                'notes' => 'Damaged during testing',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.current_stock', 8);

        $this->assertDatabaseHas('stock_movements', [
            'inventory_item_id' => $item->id,
            'movement_type' => 'damaged',
            'quantity' => -2,
        ]);
    }

    public function test_sale_deducts_inventory_stock_atomically(): void
    {
        $item = InventoryItem::create([
            'shop_id' => $this->shop->id,
            'name' => 'Tempered Glass iPhone 13',
            'item_type' => 'accessory',
            'purchase_price' => 50.00,
            'selling_price' => 200.00,
            'current_stock' => 10,
            'minimum_stock' => 2,
        ]);

        $customer = Customer::create([
            'shop_id' => $this->shop->id,
            'name' => 'Customer A',
            'mobile' => '9111122222',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/v1/sales', [
                'customer_id' => $customer->id,
                'items' => [
                    [
                        'inventory_item_id' => $item->id,
                        'item_name' => 'Tempered Glass iPhone 13',
                        'item_type' => 'accessory',
                        'quantity' => 3,
                        'unit_price' => 200.00,
                    ],
                ],
                'payment_amount' => 600.00,
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('inventory_items', [
            'id' => $item->id,
            'current_stock' => 7,
        ]);

        $this->assertDatabaseHas('stock_movements', [
            'inventory_item_id' => $item->id,
            'movement_type' => 'sale',
            'quantity' => -3,
        ]);
    }

    public function test_cannot_sell_item_with_insufficient_stock(): void
    {
        $item = InventoryItem::create([
            'shop_id' => $this->shop->id,
            'name' => 'Rare Motherboard Component',
            'item_type' => 'spare_part',
            'purchase_price' => 3000.00,
            'selling_price' => 5000.00,
            'current_stock' => 1,
            'minimum_stock' => 1,
        ]);

        $customer = Customer::create([
            'shop_id' => $this->shop->id,
            'name' => 'Customer B',
            'mobile' => '9333344444',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/v1/sales', [
                'customer_id' => $customer->id,
                'items' => [
                    [
                        'inventory_item_id' => $item->id,
                        'item_name' => 'Rare Motherboard Component',
                        'item_type' => 'spare_part',
                        'quantity' => 5, // requested 5, but stock is 1
                        'unit_price' => 5000.00,
                    ],
                ],
            ]);

        $response->assertStatus(500)
            ->assertJsonPath('success', false);

        // Stock should remain unchanged (1)
        $this->assertDatabaseHas('inventory_items', [
            'id' => $item->id,
            'current_stock' => 1,
        ]);
    }

    public function test_shop_isolation_for_inventory(): void
    {
        $otherShop = Shop::create([
            'name' => 'Other Mobile Shop',
            'owner_name' => 'Jane Smith',
            'phone' => '9998887776',
            'address' => '456 Other Rd',
        ]);

        $otherItem = InventoryItem::create([
            'shop_id' => $otherShop->id,
            'name' => 'Other Shop Display',
            'item_type' => 'spare_part',
            'purchase_price' => 5000.00,
            'selling_price' => 8000.00,
            'current_stock' => 10,
        ]);

        // User from Shop 1 tries to access Shop 2 item
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/v1/inventory/{$otherItem->id}");

        $response->assertStatus(404);
    }
}