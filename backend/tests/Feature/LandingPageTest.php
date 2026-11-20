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

    public function test_language_switch_and_local_illustration_are_shipped(): void
    {
        $html = $this->get('/')->assertOk()->getContent();
        $this->assertStringContainsString('data-lang="en"', $html);
        $this->assertStringContainsString('data-lang="ar"', $html);
        $this->assertStringContainsString('data-i18n-en="Key Features"', $html);
        $this->assertStringContainsString('landing/worksheet-scene.svg', $html);
        $this->assertFileExists(public_path('landing/worksheet-scene.svg'));
        $this->assertStringNotContainsString('</i data-i18n-', $html);
    }

    public function test_reference_aligned_layout_and_assets_are_in_source(): void
    {
        $html = $this->get('/')->assertOk()->getContent();
        $this->assertStringContainsString('class="hero-brand"', $html);
        $this->assertStringContainsString('hero-ornaments.svg', $html);
        $this->assertStringContainsString('min-height:338px;height:338px', $html);
        $this->assertStringContainsString('direction:ltr}.brand', $html);
        $this->assertSame(7, substr_count($html, 'class="glyph" aria-hidden="true"'));
        $this->assertStringContainsString('class="launch-waitlist"', $html);
        $this->assertStringContainsString('type="email" disabled', $html);
        $this->assertFileExists(public_path('landing/hero-ornaments.svg'));
        $this->assertFileExists(public_path('landing/worksheet-scene.svg'));
    }

    public function test_legal_pages_remain_available(): void
    {
        $this->get('/privacy')->assertOk();
        $this->get('/terms')->assertOk();
        $this->get('/support')->assertOk();
        $this->get('/data-deletion')->assertOk();
    }
    public function test_coming_soon_office_preview_is_bilingual_and_not_claimed_live(): void
    {
        $html = $this->get('/')->assertOk()->getContent();
        $this->assertStringContainsString('id="office-preview"', $html);
        $this->assertStringContainsString('Coming in 1.1.5', $html);
        $this->assertStringContainsString('قيد التجهيز والاختبار', $html);
        foreach (['.pdf', '.docx', '.xlsx', '.pptx'] as $extension) {
            $this->assertStringContainsString($extension, $html);
        }
    }

}
