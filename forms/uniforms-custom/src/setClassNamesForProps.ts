import classnames from 'classnames';

const setClassNamesForProps = (props: object) => {

  // @ts-ignore
  const showError = props.error != null
  const hasFloatingLabel = props.hasFloatingLabel

  return classnames({
    'u-show-error': showError,
    'hasFloatingLabel': hasFloatingLabel
  });
};

export default setClassNamesForProps;
