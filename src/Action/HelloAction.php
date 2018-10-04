<?php
namespace App\Action;

use Symfony\Component\HttpFoundation\Response;

class HelloAction
{
    public function __invoke()
    {
        return new Response('Hello prestahop');
    }
}
