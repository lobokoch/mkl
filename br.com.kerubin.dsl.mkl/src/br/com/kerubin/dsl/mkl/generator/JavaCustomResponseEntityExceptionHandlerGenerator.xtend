package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaCustomResponseEntityExceptionHandlerGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/CustomResponseEntityExceptionHandler.java'
		generateFile(fileName, generateServerConfig)
	}
	
	def CharSequence generateServerConfig() {
		'''
		package «service.servicePackage»;
		
		import java.util.List;
		import java.util.stream.Collectors;
		
		import org.springframework.http.HttpHeaders;
		import org.springframework.http.HttpStatus;
		import org.springframework.http.ResponseEntity;
		import org.springframework.http.converter.HttpMessageNotReadableException;
		import org.springframework.validation.BindingResult;
		import org.springframework.validation.FieldError;
		import org.springframework.web.bind.MethodArgumentNotValidException;
		import org.springframework.web.bind.annotation.ControllerAdvice;
		import org.springframework.web.context.request.WebRequest;
		import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
		
		@ControllerAdvice
		public class CustomResponseEntityExceptionHandler extends ResponseEntityExceptionHandler {
			
			@Override
			protected ResponseEntity<Object> handleHttpMessageNotReadable(HttpMessageNotReadableException ex,
					HttpHeaders headers, HttpStatus status, WebRequest request) {
				
				return super.handleHttpMessageNotReadable(ex, headers, status, request);
			}
			
			@Override
			protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
					HttpHeaders headers, HttpStatus status, WebRequest request) {
				
				List<String> body = buildErrorList(ex.getBindingResult());
				return handleExceptionInternal(ex, body, headers, status, request);
			}
		
			private List<String> buildErrorList(BindingResult bindingResult) {
				return bindingResult.getFieldErrors().stream().map(FieldError::getDefaultMessage).collect(Collectors.toList());
			}
		
		}
		'''
	}
	
}