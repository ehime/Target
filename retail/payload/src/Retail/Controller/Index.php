<?php
Namespace Retail\Controller
{
    USE Retail\Model\Database AS Database;

    Class Index Extends \SlimController\SlimController
    {
        public function indexAction()
        {
            $db = New Database(APP_PATH . '/src/config/mysql.ini');

            $this->render('home/index', [
                'products' => $db->query(),
            ]);
        }
    }
}
