package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServerServiceContextGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val name = service.toServiceContextName
		val fileName = basePakage + service.servicePackagePath + '/' + name  + '.java'
		generateFile(fileName, generateServiceContext)
	}
	
	def CharSequence generateServiceContext() {
		'''
		package «service.servicePackage»;
		
		public class «service.toServiceContextName» {
			
			private static ThreadLocal<String> currentTenant = new ThreadLocal<>();
			private static ThreadLocal<String> currentUser = new ThreadLocal<>();
			
			public static String getCurrentTenant() {
				return currentTenant.get();
			}
			
			public static void setCurrentTenant(String currentTenant) {
				ServiceContext.currentTenant.set(currentTenant);
			}
			
			public static void clearCurrentTenant() {
				ServiceContext.currentTenant.remove();
			}
			
			public static String getCurrentUser() {
				return currentUser.get();
			}
			
			public static void setCurrentUser(String currentUser) {
				ServiceContext.currentUser.set(currentUser);
			}
			
			public static void clearCurrentUser() {
				ServiceContext.currentUser.remove();
			}
			
			public static void clear() {
				clearCurrentTenant();
				clearCurrentUser();
			}
		
		}

		'''
	}
	
}