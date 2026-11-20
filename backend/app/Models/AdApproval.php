<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Schema;

/**
 * Explicit, reversible Super Admin advertising-policy approval.
 * Defaults to OFF and fails closed before a migration or during DB errors.
 */
class AdApproval extends Model {
    protected $fillable = ['id','approved','approved_by','approved_at'];
    protected function casts(): array {
        return ['approved'=>'boolean','approved_at'=>'datetime'];
    }
    public static function isApproved(): bool {
        try {
            return Schema::hasTable('ad_approvals')
                && (bool)(static::query()->find(1)?->approved);
        } catch (\Throwable $e) {
            return false;
        }
    }
}
