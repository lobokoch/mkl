package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServiceHandlerInterceptorAdapterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + service.toServiceHandlerInterceptorAdapterName  + '.java'
		generateFile(fileName, generateCORS)
	}
	
	def CharSequence generateCORS() {
		val domaAndService = service.toServiceConstantsName
		
		'''
		package «service.servicePackage»;
		
		import javax.servlet.http.HttpServletRequest;
		import javax.servlet.http.HttpServletResponse;
		
		import org.springframework.web.servlet.ModelAndView;
		import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;
		
		import br.com.kerubin.api.database.core.ServiceContext;
		
		public class «service.toServiceHandlerInterceptorAdapterName» extends HandlerInterceptorAdapter {
			
			public static final String HEADER_USER = "X-User-Header";
			public static final String HEADER_TENANT = "X-Tenant-Header";
			public static final String HEADER_TENANT_ACCOUNT_TYPE = "X-Tenant-AccountType-Header";
			
			@Override
			public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
					throws Exception {
				
				updateServiceContext(request);
				
				return true;
			}
			
			private void updateServiceContext(HttpServletRequest request) {
				String currentTenant = request.getHeader(HEADER_TENANT);
				String currentUser = request.getHeader(HEADER_USER);
				String currentTenantAccountType = request.getHeader(HEADER_TENANT_ACCOUNT_TYPE);
				
				ServiceContext.setTenant(currentTenant);
				ServiceContext.setUser(currentUser);
				ServiceContext.setTenantAccountType(currentTenantAccountType);
				
				ServiceContext.setDomain(«domaAndService».DOMAIN);
				ServiceContext.setService(«domaAndService».SERVICE);
				
			}
			
			@Override
			public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
					ModelAndView modelAndView) throws Exception {
				
				ServiceContext.clear();
				
			}
		
		}

		'''
	}
	
}