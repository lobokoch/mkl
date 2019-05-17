package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaObjectMapperGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private static val CLASS_NAME = 'ObjectMapper';
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + service.servicePackagePath + '/' + CLASS_NAME  + '.java'
		generateFile(fileName, doGenerate)
	}
	
	def CharSequence doGenerate() {
		'''
		package «service.servicePackage»;
		
		import java.beans.PropertyDescriptor;
		import java.lang.reflect.Field;
		import java.math.BigDecimal;
		import java.time.Instant;
		import java.time.LocalDate;
		import java.time.LocalTime;
		import java.util.Arrays;
		import java.util.Date;
		import java.util.HashMap;
		import java.util.List;
		import java.util.Map;
		import java.util.Optional;
		import java.util.UUID;
		
		import org.hibernate.Hibernate;
		import org.hibernate.collection.spi.PersistentCollection;
		import org.hibernate.proxy.HibernateProxy;
		import org.slf4j.Logger;
		import org.slf4j.LoggerFactory;
		import org.springframework.beans.BeanUtils;
		import org.springframework.stereotype.Component;
		
		@Component("«service.domain».«service.name».«CLASS_NAME»")
		public class «CLASS_NAME» {
			
			private static Logger log = LoggerFactory.getLogger(«CLASS_NAME».class);
			
			private static final List<?> DSL_PRIMITIVE_TYPES = Arrays.asList(LocalDate.class, LocalTime.class, Date.class, 
		            Instant.class, String.class, Long.class, 
		            Boolean.class, UUID.class, BigDecimal.class, Double.class);
			
			
			public <T> T map(Object source, Class<T> targetClass) {
		        if (source == null) {
		            return null;
		        }
		        
		        T target = BeanUtils.instantiateClass(targetClass);
		        copyProperties(source, target);
		        return target;
		    }
			
			public void copyProperties(Object source, Object target) {
		        Map<Object, Object> visited = new HashMap<>();
		        copyProperties(source, target, visited);
		    }
		    
		    protected void copyProperties(Object source, Object target, Map<Object, Object> visited) {
		        if (source == null || target == null) {
		            return;
		        }
		        
		        visited.put(source, target);
		        
		        List<Field> sourceFieds = Arrays.asList(source.getClass().getDeclaredFields());
		        List<Field> targetFieds = Arrays.asList(target.getClass().getDeclaredFields());
		        targetFieds.forEach(targetField -> {
		            Optional<Field> sourceFieldOptional = sourceFieds.stream().filter(it -> it.getName().equals(targetField.getName())).findFirst();
		            if (sourceFieldOptional.isPresent()) {
		                Field sourceField = sourceFieldOptional.get();
		                //targetField.setAccessible(true);
		                //sourceField.setAccessible(true);
		                try {
		                    Class<?> targetFieldType = targetField.getType();
		                    Class<?> sourceFieldType = sourceField.getType();
		                    
		                    /*if (! targetFieldType.getSimpleName().equals(sourceFieldType.getSimpleName())) {
		                    	throw new IllegalStateException("Target field '" + targetField.getName() + "' type '" + targetFieldType + "' does not match with source filed '" + sourceField.getName() + "' type '" + sourceFieldType + "'.");
		                    }*/
		                    
		                    if (DSL_PRIMITIVE_TYPES.stream().anyMatch(it -> it.equals(targetFieldType)) || (targetFieldType.isPrimitive() && sourceFieldType.isPrimitive()) ) {
		                    	Object value = getFieldValue(source, sourceField);
		                    	setFieldValue(target, targetField, value);
		                    }
		                    else if (targetFieldType.isEnum()) {
		                        if (sourceFieldType.isEnum()) {
		                        	Object value = getFieldValue(source, sourceField);
		                            if (value != null) {
			                            String sourceEnumName = ((Enum<?>) value).name();
			                            
			                            @SuppressWarnings({ "rawtypes", "unchecked" })
			                            Enum<?> targetEnumValue = Enum.valueOf( (Class<Enum>) targetFieldType, sourceEnumName);
			                            setFieldValue(target, targetField, targetEnumValue);
		                            }
		                        }
		                        else {
		                        	throw new IllegalStateException("Source \"" + sourceFieldType.getName() + "\" is not a enum.");
		                        }
		                    }
		                    else { // Is another entity reference, call recursive if needed.
		                    	Object sourceFieldValue = getFieldValue(source, sourceField);
		                    	if (isProxy(sourceFieldValue)) {
		                    		sourceFieldValue = Hibernate.unproxy(sourceFieldValue);
		                    	}
		                    	
		                        if (sourceFieldValue != null) {
		                            Object targetFieldValue = null;
		                            if (visited.containsKey(sourceFieldValue)) {
		                                targetFieldValue = visited.get(sourceFieldValue);
		                            }
		                            else {
		                                targetFieldValue = BeanUtils.instantiateClass(targetFieldType);
		                                copyProperties(sourceFieldValue, targetFieldValue, visited);
		                            }
		                            
		                            setFieldValue(target, targetField, targetFieldValue);
		                        }
		                    }
		                } catch (Exception e) {
		                	throw new IllegalStateException("Error copying properties from '" + source.getClass().getName() + "' to '" + target.getClass().getName() + "'.", e);
		                }
		            }
		            else {
		            	//throw new IllegalStateException("Target field \"" + target.getClass().getName() + "." + targetField.getName() + "\" not found in source \"" + source.getClass().getName() + "\".");
		            }
		        });
		       
		    }
		    
		    private boolean isProxy(Object value) {
		        if (value == null) {
		            return false;
		        }
		        if ((value instanceof HibernateProxy) || (value instanceof PersistentCollection)) {
		            return true;
		        }
		        return false;
		    }
		
		    
		    private void setFieldValue(Object obj, Field field, Object value) {
		    	PropertyDescriptor pd = getPropertyDescriptor(obj, field);
		    	if (pd != null && pd.getWriteMethod() != null) { // Has setter
		    		try {
						pd.getWriteMethod().invoke(obj, value);
					} catch (Exception e) {
						log.error("Erro setting object value: " + e.getMessage(), e);
					}
		    	}  else { // Does not has setter.
		    		try {
		    			field.setAccessible(true);
		    			field.set(obj, value);
					}
					catch(Exception ex) {
						log.error("Erro getting object value: " + ex.getMessage(), ex);
					}
		    	}
		    }
		    
		    private Object getFieldValue(Object obj, Field field) {
		    	PropertyDescriptor pd = getPropertyDescriptor(obj, field);
		    	Object value = null;
		    	if (pd != null && pd.getReadMethod() != null) {
		    		try {
						value = pd.getReadMethod().invoke(obj); // Has getter method
					} catch (Exception e) {
						log.error("Erro getting object value: " + e.getMessage(), e);
					}
		    	}  else { // Does not has getter.
		    		try {
		    			field.setAccessible(true);
						value = field.get(obj);
					}
					catch(Exception ex) {
						log.error("Erro getting object value: " + ex.getMessage(), ex);
					}
		    	}
		    	
		    	return value;
		    }
		    
		    private PropertyDescriptor getPropertyDescriptor(Object obj, Field field) {
		    	PropertyDescriptor pd = null;
		    	try {
		    		pd = BeanUtils.getPropertyDescriptor(obj.getClass(), field.getName());
		    	} catch(Exception e) {
		    		log.error("Erro getting property descriptor: " + e.getMessage(), e);
		    	}
		    	return pd;
		    }
		
		
		}

		'''
	}
	
}