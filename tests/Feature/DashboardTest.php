<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Device;
use App\Models\Expense;
use App\Models\ExpenseCategory;
use App\Models\InventoryItem;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    protected User $userA;
    protected Shop $shopA;
    protected User $userB;
    protected Shop $shopB;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shopA = Shop::create([
            'name' => 'Shop A Mobile Store',
            'phone' => '9999999991',
            'city' => 'Rajkot',
        ]);

        $this->userA = User::create([
            'shop_id' => $this->shopA->id,
            'name' => 'Owner A',
            'email' => 'ownera@test.com',
            'mobile' => '9999999991',
            'password' => bcrypt('password'),
        ]);

        $this->shopB = Shop::create([
            'name' => 'Shop B Mobile Store',
            'phone' => '9999999992',
            'city' => 'Ahmedabad',
        ]);

        $this->userB = User::create([
            'shop_id' => $this->shopB->id,
            'name' => 'Owner B',
            'email' => 'ownerb@test.com',
            'mobile' => '9999999992',
            'password' => bcrypt('password'),
        ]);
    }

    /** 1 & 16. Test Empty Shop Dashboard */
    public function test_empty_shop_dashboard_returns_onboarding_state(): void
    {
        $response = $this->actingAs($this->userA, 'sanctum')->getJson('/api/v1/dashboard');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('is_empty_shop', true)
            ->assertJsonPath('data.sales.total_sales', 0)
            ->assertJsonPath('data.repairs.active_repairs_count', 0)
            ->assertJsonPath('data.inventory.total_items', 0);
    }

    /** 2-15. Test Dashboard Metrics Aggregations */
    public function test_dashboard_metrics_aggregations_and_periods(): void
    {
        $nowStr = now()->format('Y-m-d');

        // Create Customer & Device
        $customer = Customer::create([
            'shop_id' => $this->shopA->id,
            'name' => 'Test Customer',
            'mobile' => '9876543210',
        ]);

        $device = Device::create([
            'shop_id' => $this->shopA->id,
            'customer_id' => $customer->id,
            'brand' => 'Apple',
            'model' => 'iPhone 13',
            'imei_1' => '123456789012345',
        ]);

        // Create Sale
        Sale::create([
            'shop_id' => $this->shopA->id,
            'invoice_number' => 'INV-0001',
            'sale_type' => 'quick',
            'sale_date' => $nowStr,
            'subtotal' => 500,
            'grand_total' => 500,
            'amount_paid' => 500,
            'amount_due' => 0,
            'payment_status' => 'paid',
            'created_by' => $this->userA->id,
        ]);

        // Create Repair
        Repair::create([
            'shop_id' => $this->shopA->id,
            'customer_id' => $customer->id,
            'device_id' => $device->id,
            'job_number' => 'JOB-0001',
            'date_received' => $nowStr,
            'problem_description' => 'Screen Broken',
            'repair_status' => 'ready',
            'estimated_cost' => 4500,
        ]);

        // Create Inventory Item (Out of Stock)
        InventoryItem::create([
            'shop_id' => $this->shopA->id,
            'name' => 'iPhone Screen',
            'item_type' => 'spare_part',
            'purchase_price' => 1500,
            'selling_price' => 3000,
            'opening_stock' => 5,
            'current_stock' => 0, // Out of stock
            'minimum_stock' => 2,
        ]);

        // Create Expense
        $category = ExpenseCategory::create([
            'shop_id' => $this->shopA->id,
            'name' => 'Shop Rent',
            'slug' => 'shop-rent',
        ]);

        Expense::create([
            'shop_id' => $this->shopA->id,
            'category_id' => $category->id,
            'title' => 'August Shop Rent',
            'amount' => 15000,
            'expense_date' => $nowStr,
        ]);

        // Request Today Period
        $response = $this->actingAs($this->userA, 'sanctum')->getJson('/api/v1/dashboard?period=today');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('is_empty_shop', false)
            ->assertJsonPath('data.sales.total_sales', 500)
            ->assertJsonPath('data.sales.quick_sales_count', 1)
            ->assertJsonPath('data.repairs.ready_count', 1)
            ->assertJsonPath('data.inventory.out_of_stock_count', 1)
            ->assertJsonPath('data.expenses.total_expenses_sum', 15000)
            ->assertJsonPath('data.expenses.top_category.name', 'Shop Rent');
    }

    /** 17. Multi-tenant shop isolation: Shop A cannot see Shop B data */
    public function test_shop_a_cannot_see_shop_b_dashboard_data(): void
    {
        // Shop B has 100,000 sales
        Sale::create([
            'shop_id' => $this->shopB->id,
            'invoice_number' => 'INV-B-0001',
            'sale_type' => 'regular',
            'sale_date' => now()->format('Y-m-d'),
            'subtotal' => 100000,
            'grand_total' => 100000,
            'amount_paid' => 100000,
            'amount_due' => 0,
            'payment_status' => 'paid',
            'created_by' => $this->userB->id,
        ]);

        // User A requests dashboard
        $responseA = $this->actingAs($this->userA, 'sanctum')->getJson('/api/v1/dashboard');

        $responseA->assertStatus(200)
            ->assertJsonPath('data.sales.total_sales', 0); // Must be 0 for Shop A!
    }
}