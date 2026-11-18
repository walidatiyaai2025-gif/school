<?php
namespace App\Http\Middleware;
use Closure; use Illuminate\Http\Request; use Symfony\Component\HttpFoundation\Response;
class RequireInstalled {
 public function handle(Request $request,Closure $next): Response {
  if (!is_file(base_path('storage/app/private/install.lock'))) abort(503,'School PDF setup is not complete. See /install');
  return $next($request);
 }
}
