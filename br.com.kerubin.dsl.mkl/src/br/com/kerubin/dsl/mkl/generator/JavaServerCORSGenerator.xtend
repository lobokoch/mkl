package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaServerCORSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/CorsFilter.java'
		generateFile(fileName, generateCORS)
	}
	
	def CharSequence generateCORS() {
		'''
		package «service.servicePackage»;
		
		import java.io.IOException;
		
		import javax.servlet.Filter;
		import javax.servlet.FilterChain;
		import javax.servlet.FilterConfig;
		import javax.servlet.ServletException;
		import javax.servlet.ServletRequest;
		import javax.servlet.ServletResponse;
		import javax.servlet.http.HttpServletRequest;
		import javax.servlet.http.HttpServletResponse;
		
		import org.springframework.core.Ordered;
		import org.springframework.core.annotation.Order;
		import org.springframework.stereotype.Component;
		
		@Component
		@Order(Ordered.HIGHEST_PRECEDENCE)
		public class CorsFilter implements Filter {
			
			// TODO: Configurar para diferentes ambientes
			private static final String ALLOW_ORIGINS = "http://localhost:4200"; 
		
			@Override
			public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain)
					throws IOException, ServletException {
				
				HttpServletRequest request = (HttpServletRequest) req;
				HttpServletResponse response = (HttpServletResponse) resp;
				
				response.setHeader("Access-Control-Allow-Origin", ALLOW_ORIGINS);
		        response.setHeader("Access-Control-Allow-Credentials", "true");
				
				if ("OPTIONS".equals(request.getMethod()) && ALLOW_ORIGINS.equals(request.getHeader("Origin"))) {
					response.setHeader("Access-Control-Allow-Methods", "POST, GET, DELETE, PUT, OPTIONS");
		        	response.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type, Accept");
		        	response.setHeader("Access-Control-Max-Age", "3600");
					
					response.setStatus(HttpServletResponse.SC_OK);
				} else {
					chain.doFilter(req, resp);
				}
			}
			
			@Override
			public void init(FilterConfig filterConfig) throws ServletException {
				// 
			}
		
		
			@Override
			public void destroy() {
				// 
			}
		
		}

		'''
	}
	
}