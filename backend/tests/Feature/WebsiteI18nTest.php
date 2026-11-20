<?php
namespace Tests\Feature;

use Tests\TestCase;

class WebsiteI18nTest extends TestCase
{
    public function test_public_landing_has_both_languages_and_persists_preference(): void
    {
        $this->get('/')->assertOk()
            ->assertSee('data-lang="en"', false)
            ->assertSee('data-lang="ar"', false)
            ->assertSee("localStorage.setItem('schoolpdf-language',lang)", false);
    }

    public function test_legal_pages_have_separate_complete_language_sections(): void
    {
        foreach (['/privacy', '/support', '/terms', '/data-deletion', '/delete-account'] as $path) {
            $this->get($path.'?lang=en')->assertOk()
                ->assertSee('lang="ar"', false)
                ->assertSee('lang="en"', false)
                ->assertSee('js/site-i18n.js', false)
                ->assertSee('data-site-languages', false);
        }
    }

    public function test_admin_login_and_i18n_assets_are_available(): void
    {
        $this->get('/admin/login')->assertOk()
            ->assertSee('data-site-languages', false);
        $this->assertFileExists(public_path('js/site-i18n.js'));
        $js = file_get_contents(public_path('js/site-i18n.js'));
        $this->assertStringContainsString('schoolpdf-language', $js);
        $this->assertStringContainsString('data-site-languages', $js);
    }
}
