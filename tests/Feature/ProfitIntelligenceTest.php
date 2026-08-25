<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\InventoryItem;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfitIntelligenceTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Shop $shop;

    protected function setUp(): void
    {
        parent::setUp();

        $this->shop = Shop::create([
            'name' => 'Intelligence Shop',
            'owner_name' => 'AI Manager',
            'phone' => '9991112220',
            'address' => '505 AI Lane',
        ]);

        $this->user = User::create([
            'shop_id' => $this->shop->id,
            'name' => 'AI User',
            'email' => 'ai@example.com',
            'mobile' => '9991112220',
            'password' => bcrypt('password123'),
            'role' => 'owner',
        ]);
    }

    public function test_can_fetch_profit_intelligence_summary(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/profit-intelligence');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'business_health' => ['score', 'rating', 'deduction_reasons'],
                    'potential_extra_profit',
                    'potential_extra_profit_formatted',
                    'cards' => [
                        'underpriced_repairs',
                        'slow_moving_stock',
                        'warranty_loss',
                        'pending_payments',
                        'low_margin_products',
                    ],
                ],
            ]);
    }

    public function test_can_fetch_profit_intelligence_category_details(): void
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/v1/profit-intelligence/details/underpriced_repairs');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['has_enough_data', 'details']]);
    }
}