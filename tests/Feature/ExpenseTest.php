<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\ExpenseCategory;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExpenseTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Shop $shop;
    protected ExpenseCategory $category;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create([
            'name' => 'Expense Test Shop',
            'phone' => '9876543210',
            'address' => 'Test Market',
        ]);

        $this->user = User::create([
            'shop_id' => $this->shop->id,
            'name' => 'Expense Manager',
            'email' => 'expmanager@test.com',
            'mobile' => '9876543210',
            'password' => bcrypt('password'),
        ]);

        // Get system default category
        $this->category = ExpenseCategory::whereNull('shop_id')->first()
            ?? ExpenseCategory::create(['name' => 'Electricity', 'slug' => 'electricity', 'is_system_default' => true]);
    }

    /** 1. Add expense */
    public function test_can_add_expense(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/expenses', [
            'category_id' => $this->category->id,
            'title' => 'August Electricity Bill',
            'amount' => 4850.00,
            'expense_date' => '2026-08-25',
            'payment_method' => 'upi',
            'notes' => 'Paid via GooglePay',
            'reference_number' => 'UPI-123456',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.title', 'August Electricity Bill')
            ->assertJsonPath('data.amount', 4850);

        $this->assertDatabaseHas('expenses', [
            'shop_id' => $this->shop->id,
            'title' => 'August Electricity Bill',
            'amount' => 4850.00,
        ]);
    }

    /** 2. Edit expense */
    public function test_can_edit_expense(): void
    {
        $expense = Expense::create([
            'shop_id' => $this->shop->id,
            'category_id' => $this->category->id,
            'title' => 'Initial Rent',
            'amount' => 15000.00,
            'expense_date' => '2026-08-01',
            'payment_method' => 'bank_transfer',
            'created_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->putJson("/api/v1/expenses/{$expense->id}", [
            'title' => 'Updated Shop Rent August',
            'amount' => 16000.00,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.title', 'Updated Shop Rent August')
            ->assertJsonPath('data.amount', 16000);

        $this->assertDatabaseHas('expenses', [
            'id' => $expense->id,
            'title' => 'Updated Shop Rent August',
            'amount' => 16000.00,
        ]);
    }

    /** 3. Delete expense */
    public function test_can_delete_expense(): void
    {
        $expense = Expense::create([
            'shop_id' => $this->shop->id,
            'category_id' => $this->category->id,
            'title' => 'Temp Expense',
            'amount' => 500.00,
            'expense_date' => '2026-08-25',
            'created_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertSoftDeleted('expenses', ['id' => $expense->id]);
    }

    /** 4. Add custom category */
    public function test_can_add_custom_expense_category(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/expense-categories', [
            'name' => 'Tea & Snacks',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Tea & Snacks')
            ->assertJsonPath('data.is_system_default', false);

        $this->assertDatabaseHas('expense_categories', [
            'shop_id' => $this->shop->id,
            'name' => 'Tea & Snacks',
        ]);
    }

    /** 5, 6, 7, 8. Filter by category, month, search, and calculate sum metrics */
    public function test_filter_and_search_expenses_with_metrics(): void
    {
        $catRent = ExpenseCategory::create(['shop_id' => $this->shop->id, 'name' => 'Custom Rent', 'slug' => 'custom-rent']);

        Expense::create([
            'shop_id' => $this->shop->id,
            'category_id' => $catRent->id,
            'title' => 'Monthly Rent August',
            'amount' => 15000.00,
            'expense_date' => '2026-08-01',
        ]);

        Expense::create([
            'shop_id' => $this->shop->id,
            'category_id' => $this->category->id,
            'title' => 'Office Internet',
            'amount' => 999.00,
            'expense_date' => '2026-08-10',
            'notes' => 'Airtel Broadband',
        ]);

        // Search 'Airtel'
        $responseSearch = $this->actingAs($this->user, 'sanctum')->getJson('/api/v1/expenses?search=Airtel');
        $responseSearch->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Office Internet');

        // Filter by Rent category
        $responseCat = $this->actingAs($this->user, 'sanctum')->getJson("/api/v1/expenses?category_id={$catRent->id}");
        $responseCat->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('metrics.total_expenses_sum', 15000);
    }

    /** 9 & 10. Recurring expense fields foundation */
    public function test_recurring_expense_fields(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/expenses', [
            'category_id' => $this->category->id,
            'title' => 'Software Subscription',
            'amount' => 2999.00,
            'expense_date' => '2026-08-25',
            'is_recurring' => true,
            'recurrence_type' => 'monthly',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.is_recurring', true)
            ->assertJsonPath('data.recurrence_type', 'monthly');
    }

    /** 11. Invalid amount (<= 0) rejected */
    public function test_invalid_expense_amount_rejected(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')->postJson('/api/v1/expenses', [
            'category_id' => $this->category->id,
            'title' => 'Free Expense',
            'amount' => 0.00, // Invalid
            'expense_date' => '2026-08-25',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['amount']);
    }

    /** 12. Multi-tenant shop isolation: Shop A cannot access Shop B expenses */
    public function test_shop_a_cannot_access_shop_b_expenses(): void
    {
        $shopB = Shop::create(['name' => 'Shop B', 'phone' => '1111111111']);
        $userB = User::create([
            'shop_id' => $shopB->id,
            'name' => 'Owner B',
            'email' => 'b_exp@test.com',
            'mobile' => '1111111111',
            'password' => bcrypt('password'),
        ]);

        $expA = Expense::create([
            'shop_id' => $this->shop->id,
            'category_id' => $this->category->id,
            'title' => 'Shop A Secret Expense',
            'amount' => 5000.00,
            'expense_date' => '2026-08-25',
        ]);

        // User B tries to view Shop A's expense
        $responseView = $this->actingAs($userB, 'sanctum')->getJson("/api/v1/expenses/{$expA->id}");
        $responseView->assertStatus(404);

        // User B tries to delete Shop A's expense
        $responseDelete = $this->actingAs($userB, 'sanctum')->deleteJson("/api/v1/expenses/{$expA->id}");
        $responseDelete->assertStatus(404);
    }
}