package br.com.kerubin.dsl.mkl.generator

import java.util.regex.Pattern

class Utils {
	
	static val REGEX_FIND_WORD = '(?i).*?\\b%s\\b.*?';
	
	// JAVA
	static val MAIN_APP_NAME = 'Kerubin'
	static val PROJECT_PARENT = 'parent'
	static val PROJECT_CLIENT = 'client'
	static val PROJECT_SERVER = 'server'
	static val PROJECT_APPLICATION = 'app'
	static val BASE_MODULES_DIR = 'modules/'
	static val BASE_SERVER_DIR = BASE_MODULES_DIR + PROJECT_SERVER + '/'
	static val BASE_CLIENT_DIR = BASE_MODULES_DIR + PROJECT_CLIENT + '/'
	static val BASE_APPLICATION_DIR = ""//BASE_MODULES_DIR + PROJECT_APPLICATION + '/'
	static val SOURCE_GEN_BASE_DIR = 'src-gen/'
	//static val SOURCE_GEN_BASE_DIR = 'src/'
	static val SOURCE_BASE_DIR = 'src/'
	static val JAVA_BASE_DIR = 'main/java/'
	static val RESOURCES_BASE_DIR = 'main/resources/'
	static val JAVA_TEST_BASE_DIR = 'test/java/'
	static val RESOURCES_TEST_BASE_DIR = 'test/resources/'
	static val SERVER_SOURCE_GEN_DIR = BASE_SERVER_DIR + SOURCE_GEN_BASE_DIR
	static val CLIENT_SOURCE_GEN_DIR = BASE_CLIENT_DIR + SOURCE_GEN_BASE_DIR
	
	static val APPLICATION_SOURCE_GEN_DIR = BASE_APPLICATION_DIR + SOURCE_BASE_DIR
	static val APPLICATION_RESOURCES_GEN_DIR = BASE_APPLICATION_DIR + SOURCE_GEN_BASE_DIR + RESOURCES_BASE_DIR
	static val APPLICATION_RESOURCES_DIR = BASE_APPLICATION_DIR + SOURCE_BASE_DIR + RESOURCES_BASE_DIR
	
	static val SERVER_SOURCE_DIR = BASE_SERVER_DIR + SOURCE_BASE_DIR
	static val CLIENT_SOURCE_DIR = BASE_CLIENT_DIR + SOURCE_BASE_DIR
	
	// WEB
	static val WEB_BASE_DIR = 'web/'
	static val WEB_SOURCE_GEN_BASE_DIR = 'src-gen/'
	static val WEB_PROJECT_APPLICATION = 'app/'
	static val WEB_MODULES_DIR = 'modules/'
	static val WEB_MODEL_DIR = 'model/'
	static val WEB_NAVBAR_DIR = 'navbar/'
	static val WEB_MENU_DIR = 'menu/'
	static val WEB_SECURITY_DIR = 'security/'
	static val WEB_ACCOUNT_DIR = 'account/'
	static val WEB_SEARCH_CEP_DIR = 'searchcep/'
	static val WEB_ENVIRONMENTS_DIR = 'environments/'
	static val WEB_CORE_DIR = 'core/'
	static val WEB_DIRECTIVE_DIR = 'directive/'
	
	def static getWebSourceGenDir() {
		WEB_SOURCE_GEN_BASE_DIR
	}
	
	def static getWebModelDir(String path) {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + WEB_PROJECT_APPLICATION + path + WEB_MODEL_DIR
	}
	
	def static getWebComponentDir(String path) {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + WEB_PROJECT_APPLICATION + path
	}
	
	def static getWebDirectiveDir() {
		WEB_DIRECTIVE_DIR.webDir
	}
	
	def static getWebSearchCEPDir() {
		WEB_SEARCH_CEP_DIR.webDir
	}
	
	def static getWebSecurityDir() {
		WEB_SECURITY_DIR.webDir
	}
	
	def static getWebAccountDir() {
		WEB_ACCOUNT_DIR.webDir
	}
	
	def static getWebSrcDir() {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR
	}
	
	def static getWebEnvironmentsDir() {
		WEB_ENVIRONMENTS_DIR.webAppDir
	}
	
	def static getWebCoreDir() {
		WEB_CORE_DIR.webDir
	}
	
	def static getWebAppDir(String path) {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + path
	}
	
	def static getWebDir(String path) {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + WEB_PROJECT_APPLICATION + path
	}
	
	def static getWebModulesDir(String path) {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + WEB_PROJECT_APPLICATION + WEB_MODULES_DIR + path
	}
	
	def static getWebAppDir() {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + WEB_PROJECT_APPLICATION
	}
	
	def static getWebNavbarDir() {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + WEB_PROJECT_APPLICATION + WEB_NAVBAR_DIR
	}
	
	def static getWebMenuDir() {
		WEB_BASE_DIR + WEB_SOURCE_GEN_BASE_DIR + WEB_PROJECT_APPLICATION + WEB_MENU_DIR
	}
	// WEB
	
	def static getMainAppName() {
		MAIN_APP_NAME
	}
	
	def static getJavaSourceGen() {
		SOURCE_GEN_BASE_DIR + JAVA_BASE_DIR
	}
	
	def static getJavaTestSourceGen() {
		SOURCE_GEN_BASE_DIR + JAVA_TEST_BASE_DIR
	}
	
	def static getJavaTestResourceGen() {
		SOURCE_GEN_BASE_DIR + RESOURCES_TEST_BASE_DIR
	}
	
	def static getProjectParentName() {
		PROJECT_PARENT
	}
	
	def static getProjectClientName() {
		PROJECT_CLIENT
	}
	
	def static getProjectServerName() {
		PROJECT_SERVER
	}
	
	def static getProjectApplicationName() {
		PROJECT_APPLICATION
	}
	
	def static getModulesDir() {
		BASE_MODULES_DIR
	}
	
	def static getServerBaseDir() {
		BASE_SERVER_DIR
	}
	
	def static getClientrBaseDir() {
		BASE_SERVER_DIR
	}
	
	def static getServerGenSourceFolder() {
		SERVER_SOURCE_GEN_DIR + JAVA_BASE_DIR
	}
	
	def static getServerTestGenSourceFolder() {
		SERVER_SOURCE_GEN_DIR + JAVA_TEST_BASE_DIR
	}
	
	def static getServerTestResourceGenSourceFolder() {
		SERVER_SOURCE_GEN_DIR + RESOURCES_TEST_BASE_DIR
	}
	
	def static getClientGenSourceFolder() {
		CLIENT_SOURCE_GEN_DIR + JAVA_BASE_DIR
	}
	
	def static getServerSourceFolder() {
		SERVER_SOURCE_DIR + JAVA_BASE_DIR
	}
	
	def static getApplicationSourceFolder() {
		APPLICATION_SOURCE_GEN_DIR + JAVA_BASE_DIR
	}
	
	def static getApplicationGenResourcesFolder() {
		APPLICATION_RESOURCES_GEN_DIR
	}
	
	def static getApplicationResourcesFolder() {
		APPLICATION_RESOURCES_DIR
	}
	
	def static getClientSourceFolder() {
		CLIENT_SOURCE_DIR + JAVA_BASE_DIR
	}
	
	def static getWebGenSourceFolder() {
		CLIENT_SOURCE_GEN_DIR + JAVA_BASE_DIR
	}
	
	def static String removeUnderline(String str) {
		var result = str.replace('_', '')
		result
	}
	
	def static String toCamelCase(String name) {
		// foo_baa > FooBaa
		val result = name.split('_').map[toFirstUpper].join
		result
	}
	
	def static String webName(String str) {
		var result = str.toLowerCase.replace('_', '')
		result
	}
	
	def static isNotEmpty(String value) {
		value !== null && !value.trim.isEmpty
	}
	
	def static isEmpty(String value) {
		value === null || value.trim.isEmpty
	}
	
	def static StringBuilder concatSB(StringBuilder sb, String value) {
		if (sb.length > 0) {
			sb.append(' ')
		}
		sb.append(value);
	}
	
	def static StringBuilder concatSB(StringBuilder sb, CharSequence value) {
		if (sb.length > 0) {
			sb.append(' ')
		}
		sb.append(value);
	}
	
	
	def static boolean containsWord(String text, String word) {
		if (text === null || word === null) {
			return false
		}
	    val regex = String.format(REGEX_FIND_WORD, Pattern.quote(word));
	    return text.matches(regex);
	}
}