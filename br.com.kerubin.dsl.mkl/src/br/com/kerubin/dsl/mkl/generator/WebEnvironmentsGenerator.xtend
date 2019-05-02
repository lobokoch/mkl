package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebEnvironmentsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val environmentsPath = getWebEnvironmentsDir
		environmentsPath.generateEnvironments
	}
	
	def generateEnvironments(String environmentsPath) {
		val name = environmentsPath + 'environment'
		name.generateEnvironmentProd
		name.generateEnvironment
	}
	
	def generateEnvironmentProd(String name) {
		val fileName = name + '.prod.ts'
		generateFile(fileName, generateEnvironmentProdTSContent)
	}
	
	def CharSequence generateEnvironmentProdTSContent() {
		'''
		export const environment = {
		  production: true,
		
		  apiUrl: 'https://www.kerubin.com.br',
		  tokenWhitelistedDomains: [ new RegExp('www.kerubin.com.br') ],
		  tokenBlacklistedRoutes: [ new RegExp('\/oauth\/token') ]
		};
		'''
	}
	
	def generateEnvironment(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateEnvironmentTSContent)
	}
	
	def CharSequence generateEnvironmentTSContent() {
		'''
		// This file can be replaced during build by using the `fileReplacements` array.
		// `ng build ---prod` replaces `environment.ts` with `environment.prod.ts`.
		// The list of file replacements can be found in `angular.json`.
		
		export const environment = {
		  production: false,
		  apiUrl: 'http://localhost:9090/api',
		  authApiUrl: 'http://localhost:9090/api',
		
		  tokenWhitelistedDomains: [
		    new RegExp('localhost:9090')
		  ],
		
		  tokenBlacklistedRoutes: [
		    new RegExp('\/oauth\/token')
		  ]
		};
		
		/*
		 * In development mode, for easier debugging, you can ignore zone related error
		 * stack frames such as `zone.run`/`zoneDelegate.invokeTask` by importing the
		 * below file. Don't forget to comment it out in production mode
		 * because it will have a performance impact when errors are thrown
		 */
		// import 'zone.js/dist/zone-error';  // Included with Angular CLI.

		'''
	}
	
	
	
}