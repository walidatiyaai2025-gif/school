<?php
namespace Tests\Feature;
use Tests\TestCase;

class LandingPageTest extends TestCase
{
    public function test_public_landing_contains_expected_sections_and_policy_links(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('School PDF')
            ->assertSee('قريبًا إطلاق التطبيق الرسمي')
            ->assertSee('أهم المميزات')
            ->assertSee('صور من التطبيق')
            ->assertSee('كيف يعمل التطبيق؟')
            ->assertSee('Google Play')
            ->assertSee('App Store')
            ->assertSee('/privacy')
            ->assertSee('/data-deletion')
            ->assertSee('/support');
    }

    public function test_store_badges_are_not_download_links_before_release(): void
    {
        $html = $this->get('/')->assertOk()->getContent();
        $this->assertSame(2, substr_count($html, 'class="store" aria-disabled="true"'));
        $this->assertStringNotContainsString('play.google.com/store/apps/details', $html);
        $this->assertStringNotContainsString('apps.apple.com/app/', $html);
    }

    public function test_legal_pages_remain_available(): void
    {
        $this->get('/privacy')->assertOk();
        $this->get('/terms')->assertOk();
        $this->get('/support')->assertOk();
        $this->get('/data-deletion')->assertOk();
    }
}
