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
use App\Models\Warranty;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Shop $shop;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create([
            'name' => 'Analytics Shop',
            'owner_name' => 'Report Manager',
            'phone' => '9998887770',
            'address' => '101 Analytics Blvd',
        ]);

        $this->user = User::create([
            'shop_id' => $this->shop->id,
            'name' => 'Report User',
            'email' => 'report@example.com',
            'mobile' => '9998887770',
            'password' => bcrypt('password123'),
            'role' => 'owner',
        ]);
    }

    public function test_can_fetch_sales_report(): void
    {
        Sale::create([
            'shop_id' => $this->shop->id,
            'sale_type' => 'regular',
            'customer_name' => 'John Doe',
            'invoice_number' => 'INV-000001',
            'sale_date' => now(),
            'subtotal' => 1000.00,
            'discount' => 100.00,
            'grand_total' => 900.00,
            'amount_paid' => 900.00,
            'amount_due' => 0.00,
            'payment_status' => 'paid',
            'created_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/reports/sales?period=this_month');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.total_sales', 900)
            ->assertJsonPath('data.summary.total_transactions', 1);
    }

    public function test_can_fetch_repair_report(): void
    {
        $cust = Customer::create(['shop_id' => $this->shop->id, 'name' => 'Repair Cust', 'mobile' => '9876543211']);
        $dev = Device::create(['shop_id' => $this->shop->id, 'customer_id' => $cust->id, 'brand' => 'Samsung', 'model' => 'S21']);

        Repair::create([
            'shop_id' => $this->shop->id,
            'customer_id' => $cust->id,
            'device_id' => $dev->id,
            'job_number' => 'JOB-000001',
            'problem_description' => 'Broken Screen',
            'repair_status' => 'completed',
            'estimated_cost' => 1500.00,
            'date_received' => now(),
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/reports/repairs?period=this_month');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.total_repairs', 1)
            ->assertJsonPath('data.summary.completed', 1)
            ->assertJsonPath('data.summary.repair_revenue', 1500);
    }

    public function test_can_fetch_inventory_report(): void
    {
        InventoryItem::create([
            'shop_id' => $this->shop->id,
            'name' => 'Tempered Glass',
            'category' => 'General',
            'item_type' => 'accessory',
            'purchase_price' => 50.00,
            'selling_price' => 150.00,
            'opening_stock' => 20,
            'current_stock' => 20,
            'minimum_stock' => 5,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/reports/inventory?period=this_month');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.total_items', 1)
            ->assertJsonPath('data.summary.total_inventory_value', 1000);
    }

    public function test_can_fetch_expense_report(): void
    {
        $cat = ExpenseCategory::create(['shop_id' => $this->shop->id, 'name' => 'Utilities', 'slug' => 'utilities']);

        Expense::create([
            'shop_id' => $this->shop->id,
            'category_id' => $cat->id,
            'title' => 'Electricity Bill',
            'amount' => 2500.00,
            'expense_date' => now(),
            'payment_method' => 'upi',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/reports/expenses?period=this_month');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.total_expenses', 2500);
    }

    public function test_can_fetch_payments_report(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/reports/payments?period=this_month');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_can_fetch_customer_report(): void
    {
        Customer::create([
            'shop_id' => $this->shop->id,
            'name' => 'Alice Smith',
            'mobile' => '9876500001',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/reports/customers?period=this_month');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.total_customers', 1);
    }

    public function test_can_fetch_warranty_report(): void
    {
        $cust = Customer::create(['shop_id' => $this->shop->id, 'name' => 'Bob', 'mobile' => '9876500002']);
        $device = Device::create(['shop_id' => $this->shop->id, 'customer_id' => $cust->id, 'brand' => 'Apple', 'model' => 'iPhone 13']);

        Warranty::create([
            'shop_id' => $this->shop->id,
            'customer_id' => $cust->id,
            'device_id' => $device->id,
            'warranty_number' => 'WAR-000001',
            'item_name' => 'Battery Replacement',
            'warranty_type' => 'repair',
            'warranty_period_months' => 6,
            'warranty_start_date' => now(),
            'warranty_end_date' => now()->addMonths(6),
            'status' => 'active',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/reports/warranties?period=this_month');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.total_warranties', 1)
            ->assertJsonPath('data.summary.active', 1);
    }

    public function test_can_export_sales_report_csv(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->get('/api/v1/reports/export?type=sales&period=this_month');

        $response->assertStatus(200)
            ->assertHeader('Content-Type', 'text/csv; charset=UTF-8');
    }
}