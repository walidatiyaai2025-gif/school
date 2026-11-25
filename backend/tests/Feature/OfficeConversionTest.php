<?php
namespace Tests\Feature;

use Tests\TestCase;

class OfficeConversionTest extends TestCase
{
    public function test_conversion_is_disabled_by_default(): void
    {
        config()->set('services.schoolpdf_office.enabled', false);
        $response = $this->post('/api/v1/documents/convert');
        $this->assertContains($response->getStatusCode(), [403, 503]);
    }
}
