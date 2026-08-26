<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\InventoryItem;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BusinessAssistantTest extends TestCase
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
            'name' => 'Shop A Store',
            'phone' => '9876543210',
            'city' => 'Mumbai',
        ]);

        $this->userA = User::create([
            'shop_id' => $this->shopA->id,
            'name' => 'Owner A',
            'email' => 'ownera@test.com',
            'mobile' => '9876543210',
            'password' => bcrypt('password'),
        ]);

        $this->shopB = Shop::create([
            'name' => 'Shop B Store',
            'phone' => '9876543211',
            'city' => 'Delhi',
        ]);

        $this->userB = User::create([
            'shop_id' => $this->shopB->id,
            'name' => 'Owner B',
            'email' => 'ownerb@test.com',
            'mobile' => '9876543211',
            'password' => bcrypt('password'),
        ]);
    }

    public function test_unauthenticated_user_cannot_access_business_assistant(): void
    {
        $response = $this->getJson('/api/v1/business-assistant');
        $response->assertStatus(401);
    }

    public function test_empty_shop_returns_insufficient_data_notice(): void
    {
        $response = $this->actingAs($this->userA, 'sanctum')->getJson('/api/v1/business-assistant');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.has_sufficient_data', false)
            ->assertJsonPath('data.total_actions_count', 0);
    }

    public function test_payment_pending_recommendation(): void
    {
        $customer = Customer::create([
            'shop_id' => $this->shopA->id,
            'name' => 'Ramesh Kumar',
            'mobile' => '9998887776',
        ]);

        Sale::create([
            'shop_id' => $this->shopA->id,
            'customer_id' => $customer->id,
            'invoice_number' => 'INV-1001',
            'sale_type' => 'regular',
            'sale_date' => now()->format('Y-m-d'),
            'subtotal' => 15500,
            'grand_total' => 15500,
            'amount_paid' => 0,
            'amount_due' => 15500,
            'payment_status' => 'due',
            'created_by' => $this->userA->id,
        ]);

        $response = $this->actingAs($this->userA, 'sanctum')->getJson('/api/v1/business-assistant');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.has_sufficient_data', true);

        $recs = $response->json('data.recommendations');
        $this->assertNotEmpty($recs);
        $paymentRec = $recs[0];

        $this->assertEquals('COLLECT PAYMENT', $paymentRec['title']);
        $this->assertEquals('high', $paymentRec['priority']);
        $this->assertEquals('/sales', $paymentRec['route']);
    }

    public function test_multi_tenant_isolation_for_recommendations(): void
    {
        // Shop B has high unpaid sales
        Customer::create([
            'shop_id' => $this->shopB->id,
            'name' => 'Shop B Customer',
            'mobile' => '9991112223',
        ]);

        Sale::create([
            'shop_id' => $this->shopB->id,
            'invoice_number' => 'INV-B-999',
            'sale_type' => 'regular',
            'sale_date' => now()->format('Y-m-d'),
            'subtotal' => 50000,
            'grand_total' => 50000,
            'amount_paid' => 0,
            'amount_due' => 50000,
            'payment_status' => 'due',
            'created_by' => $this->userB->id,
        ]);

        // User A requests recommendations
        $responseA = $this->actingAs($this->userA, 'sanctum')->getJson('/api/v1/business-assistant');
        $responseA->assertStatus(200)
            ->assertJsonPath('data.has_sufficient_data', false);
    }

    public function test_dashboard_endpoint_includes_business_assistant_summary(): void
    {
        $response = $this->actingAs($this->userA, 'sanctum')->getJson('/api/v1/dashboard');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'business_assistant' => [
                        'total_count',
                        'top_summaries',
                    ],
                ],
            ]);
    }
}
