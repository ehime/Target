<?php

Namespace Document\Controller
{
    USE Document\Controller\Search\Regex AS Regex;
    USE Document\Controller\Search\Brute AS Brute;
    USE Document\Controller\Search\Index AS Index;

    Class Bootstrap
    {
        protected $params = [];

        private $filter = [
            'file' => [
                'filter' => FILTER_VALIDATE_REGEXP,
                'flags' => FILTER_NULL_ON_FAILURE,
                /**
                 * Matches the following scenarios
                 * "./"
                 * "../"
                 * "........" (yes this can be a file's name)
                 * "file/file.txt"
                 * "file/file"
                 * "file.txt"
                 * "file/.././/file/file/file"
                 * "/file/.././/file/file/.file" (UNIX)
                 * "C:\Windows\" (Windows)
                 * "C:\Windows\asd/asd" (Windows, php accepts this)
                 * "file/.././/file/file/file!@#$"
                 * "file/.././/file/file/file!@#.php.php.php.pdf.php"
                 */
                'options' => ['regexp' => '/^[^*?"<>|:]*$/']
            ],

            'type' => [
                'filter' => FILTER_VALIDATE_REGEXP,
                'flags' => FILTER_NULL_ON_FAILURE,
                /**
                 * Matches A-Z non-sensitive
                 */
                'options' => ['regexp' => '/^[A-Z]+$/i']
            ],

            'find' => [
                /**
                 * Removes all characters except letters,
                 * digits and $-_.+!*'(),{}|\\^~[]`<>#%";/?:@&=.
                 */
                'filter' => FILTER_SANITIZE_URL,
            ],

            'strip' => [
                /**
                 * Removes all characters except letters,
                 * digits and $-_.+!*'(),{}|\\^~[]`<>#%";/?:@&=.
                 */
                'filter' => FILTER_SANITIZE_URL,
            ],

            'common' => [ 'filter' => FILTER_VALIDATE_BOOLEAN ],
        ];

        public function __construct(array $payload = [])
        {
            if (! defined('CLI')) define('CLI', (! $payload['type'] ?: 0));

            /**
             * Move below to some other parsing class
             * GET will be altered with POST sometime
             * later(ish)
             */

            // convert CLI opts to GET params if you're playing from the command line
            if (CLI) parse_str(implode("&", array_slice($payload['args'], 1)), $_GET);
            if (2 === $payload['type']) $_GET = $payload['args'];

            $this->params = $_GET;
            $this->keysExist();
        }

        public function run()
        {
            $this->params = filter_var_array($this->params, $this->filter);
            $type = '\\Document\\Controller\\Search\\' . ucfirst(strtolower($this->params['type']));

            return New $type($this->params);

        }

        /**
         * @return $this
         */
        private function keysExist()
        {
            // not required.. so unset if empty...
            if (empty($this->params['strip']))  unset($this->filter['strip']);
            if (empty($this->params['common'])) unset($this->filter['common']);

            foreach (array_keys($this->filter) AS $key) {
                if (empty($this->params[$key])) Throw New \RuntimeException("{$key} is required, but argument was not found...");
            }

            return $this;
        }
    }
}