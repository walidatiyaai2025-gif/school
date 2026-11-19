<?php
namespace Tests\Feature;

use Tests\TestCase;

class LegalPagesTest extends TestCase
{
    public function test_public_privacy_support_and_deletion_pages_show_official_contact(): void
    {
        foreach (['/privacy', '/support', '/data-deletion', '/delete-account', '/terms'] as $path) {
            $this->get($path)->assertOk()
                ->assertSee('info@50sols.com')
                ->assertSee('School PDF');
        }
    }

    public function test_deletion_page_explains_no_consumer_accounts_and_two_deletion_paths(): void
    {
        $this->get('/data-deletion')->assertOk()
            ->assertSee('Delete server device record')
            ->assertSee('Delete local profile and PDFs')
            ->assertSee('No student account is created.')
            ->assertSee('mailto:info@50sols.com', false);
    }

    public function test_privacy_page_has_a_deletion_link_and_is_not_a_draft(): void
    {
        $this->get('/privacy')->assertOk()
            ->assertSee('/data-deletion')
            ->assertDontSee('Draft v1.1.1');
    }
}
